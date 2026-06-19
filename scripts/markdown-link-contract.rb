#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'uri'
require 'cgi'

module MarkdownLinkContract
  SCHEME_PATTERN = /\A[a-z][a-z0-9+.-]*:/i.freeze
  INVALID_ESCAPE_PATTERN = /%(?![0-9a-f]{2})/i.freeze
  ESCAPABLE_PUNCTUATION_PATTERN = /[!"#$%&'()*+,\-.\/:;<=>?@\[\\\]^_`{|}~]/.freeze
  COMMONMARK_HTML_BLOCK_TAGS = %w[
    address article aside base basefont blockquote body caption center col
    colgroup dd details dialog dir div dl dt fieldset figcaption figure footer
    form frame frameset h1 h2 h3 h4 h5 h6 head header hr html iframe legend
    li link main menu menuitem nav noframes ol optgroup option p param search
    section summary table tbody td tfoot th thead title tr track ul
  ].freeze
  COMMONMARK_HTML_BLOCK_PATTERN =
    /\A<\/?(?:#{COMMONMARK_HTML_BLOCK_TAGS.join('|')})(?:[ \t>\/]|\z)/i.freeze

  module_function

  def validate(source, root)
    failures = []
    links(source.read).each do |link|
      if link[:error]
        failures << "contains malformed local link #{link[:raw].inspect}: #{link[:error]}"
        next
      end

      target = link[:path].empty? ? source : source.dirname.join(link[:path]).cleanpath
      within_repository = target == root || target.to_s.start_with?("#{root}#{File::SEPARATOR}")
      unless within_repository && exact_regular_file?(target, root)
        failures << "references missing or unsafe local target #{link[:path].inspect}"
        next
      end

      next if link[:fragment].nil? || link[:fragment].empty?

      unless target.extname.downcase == '.md'
        failures << "references fragment #{link[:fragment].inspect} on non-Markdown target #{link[:path].inspect}"
        next
      end

      unless heading_anchors(target.read).include?(link[:fragment])
        failures << "references missing Markdown anchor #{link[:fragment].inspect} in #{link[:path].inspect}"
      end
    end
    failures
  end

  def links(contents)
    markdown_segments(contents).flat_map { |segment| scan_inline_links(segment) }
  end

  def scan_inline_links(contents)
    visible_contents = mask_inline_code_spans(mask_raw_html_blocks(mask_html_comments(contents)))
    scan_link_uses(mask_reference_definition_lines(visible_contents), reference_definitions(visible_contents))
  end

  def scan_link_uses(contents, definitions, images_only: false)
    links = []
    index = 0

    while index < contents.length
      opener = next_link_text_opener(contents, index)
      break unless opener

      text_start = contents[opener] == '!' ? opener + 2 : opener + 1
      text_end = matching_bracket(contents, text_start)
      unless text_end
        index = opener + 1
        next
      end

      image = contents[opener] == '!'
      link_text = contents[text_start...text_end]

      if contents[text_end + 1] == '('
        parsed = parse_parenthesized_destination(contents, text_end + 2)
        if parsed
          links.concat(scan_link_text_links(link_text, definitions,
                                            current_is_image: image,
                                            rendered_container: true,
                                            images_only: images_only))
          link = link_for_target(parsed[:target], parsed[:raw])
          links << link if link && (!images_only || image)
          index = parsed[:end_index]
        else
          links.concat(scan_link_text_links(link_text, definitions,
                                            current_is_image: image,
                                            rendered_container: false,
                                            images_only: images_only))
          index = text_end + 1
        end
        next
      end

      if contents[text_end + 1] == '['
        label_end = matching_bracket(contents, text_end + 2)
        unless label_end
          index = text_end + 1
          next
        end

        label = contents[(text_end + 2)...label_end]
        label = contents[text_start...text_end] if label.empty?
        definition_label = normalize_reference_label(label)
        if definitions.key?(definition_label)
          links.concat(scan_link_text_links(link_text, definitions,
                                            current_is_image: image,
                                            rendered_container: true,
                                            images_only: images_only))
          definition = definitions[definition_label]
          links << definition.dup if definition && (!images_only || image)
        else
          links.concat(scan_link_text_links(link_text, definitions,
                                            current_is_image: image,
                                            rendered_container: false,
                                            images_only: images_only))
        end
        index = label_end + 1
        next
      end

      definition_label = normalize_reference_label(contents[text_start...text_end])
      if definitions.key?(definition_label)
        links.concat(scan_link_text_links(link_text, definitions,
                                          current_is_image: image,
                                          rendered_container: true,
                                          images_only: images_only))
        definition = definitions[definition_label]
        links << definition.dup if definition && (!images_only || image)
      else
        links.concat(scan_link_text_links(link_text, definitions,
                                          current_is_image: image,
                                          rendered_container: false,
                                          images_only: images_only))
      end
      index = text_end + 1
    end

    links.compact
  end

  def scan_link_text_links(contents, definitions, current_is_image:, rendered_container:, images_only:)
    return [] if current_is_image

    nested_images_only = rendered_container ? true : images_only
    scan_link_uses(contents, definitions, images_only: nested_images_only)
  end

  def reference_definitions(contents)
    definitions = {}
    reference_definition_spans(contents.lines).each do |parsed|
      if definitions.key?(parsed[:label])
        next
      end

      definitions[parsed[:label]] = parsed[:link]
    end

    definitions
  end

  def parse_reference_definition_lines(lines, index)
    line = reference_definition_start_line(lines[index])
    return nil unless line

    start = line[/\A {0,3}/].length
    return nil unless line[start] == '['

    label_end = matching_bracket(line, start + 1)
    return nil unless label_end && line[label_end + 1] == ':'

    raw_label = line[(start + 1)...label_end]
    return nil unless valid_reference_label?(raw_label)

    label = normalize_reference_label(raw_label)
    return nil if footnote_label?(label)

    destination_line = line
    destination_index = label_end + 2
    next_index = index + 1
    if line[destination_index..].to_s.strip.empty?
      return nil if next_index >= lines.length

      destination_line = reference_continuation_line(lines[next_index])
      return nil unless destination_line.match?(/\A {0,3}\S/)

      destination_index = destination_line[/\A {0,3}/].length
      next_index += 1
    end

    parsed = parse_reference_destination(destination_line, destination_index)
    return nil unless parsed
    next_index = reference_definition_next_index(lines, next_index, destination_line, parsed[:end_index])
    return nil unless next_index

    {
      label: label,
      link: link_for_target(parsed[:target], parsed[:raw]),
      start_index: index,
      next_index: next_index
    }
  end

  def mask_reference_definition_lines(contents)
    lines = contents.lines
    masked = []
    index = 0

    reference_definition_spans(lines).each do |parsed|
      while index < parsed[:start_index]
        masked << lines[index]
        index += 1
      end

      while index < parsed[:next_index]
        masked << mask_preserving_newlines(lines[index])
        index += 1
      end
    end

    while index < lines.length
      masked << lines[index]
      index += 1
    end

    masked.join
  end

  def reference_definition_spans(lines)
    spans = []
    index = 0
    block_start = true

    while index < lines.length
      current_block_start = block_start
      parsed = reference_definition_may_start?(lines[index], block_start) ? parse_reference_definition_lines(lines, index) : nil
      if parsed
        spans << parsed
        index = parsed[:next_index]
        block_start = true
        next
      end

      block_start = reference_definition_can_follow_line?(reference_continuation_line(lines[index]).to_s,
                                                          current_block_start)
      index += 1
    end

    spans
  end

  def reference_definition_may_start?(line, block_start)
    block_start || reference_definition_container_start?(line, block_start)
  end

  def reference_definition_container_start?(line, block_start)
    content = line.to_s.chomp
    indent = content[/\A */].length
    return false if indent > 3
    return true if content[indent] == '>'

    marker = content[indent..].to_s.match(/\A(?<marker>[-+*]|\d{1,9}[.)])(?:[ \t]+|\z)/)
    marker && container_marker_can_interrupt_paragraph?(marker[:marker], block_start)
  end

  def reference_definition_can_follow_line?(content, block_start)
    return true if content.strip.empty?
    return true if content.match?(/\A {0,3}\#{1,6}(?:[ \t]+|\z)/)
    return true if block_start && indented_code_line?(content)

    thematic = content.sub(/\A {0,3}/, '')
    marker = thematic.delete(" \t")
    marker.length >= 3 && marker.chars.uniq.length == 1 && ['-', '*', '_'].include?(marker[0])
  end

  def indented_code_line?(content)
    content.match?(/\A(?: {4}|\t)/)
  end

  def reference_definition_start_line(line)
    content = reference_continuation_line(line)
    return nil unless content

    start = content[/\A {0,3}/].length
    return content if content[start] == '['

    marker = content[start..].to_s.match(/\A(?:[-+*]|\d{1,9}[.)])([ \t]+)/)
    return nil unless marker

    after_marker = start + marker[0].length
    content[after_marker] == '[' ? content[after_marker..] : nil
  end

  def reference_continuation_line(line)
    return nil unless line

    content = line.chomp
    loop do
      indent = content[/\A */].length
      return content unless indent <= 3 && content[indent] == '>'

      content = content[(indent + 1)..].to_s
      content = content[1..].to_s if [' ', "\t"].include?(content[0])
    end
  end

  def parse_parenthesized_destination(contents, index)
    index = skip_link_spacing(contents, index)
    parsed = contents[index] == '<' ? parse_angle_destination(contents, index) : parse_bare_destination(contents, index, stop_at_space: true)
    return nil unless parsed

    index = skip_link_spacing(contents, parsed[:end_index])
    unless contents[index] == ')'
      return nil if index == parsed[:end_index]

      title = parse_optional_title(contents, index)
      return nil unless title

      index = skip_link_spacing(contents, title)
      return nil unless contents[index] == ')'
    end

    parsed.merge(end_index: index + 1)
  end

  def parse_reference_destination(contents, index)
    index = skip_spaces(contents, index)
    return nil if index >= contents.length

    contents[index] == '<' ? parse_angle_destination(contents, index) : parse_bare_destination(contents, index, stop_at_space: true, allow_end: true)
  end

  def parse_angle_destination(contents, index)
    cursor = index + 1
    target = +''
    while cursor < contents.length
      return nil if contents[cursor] == "\n"

      if contents[cursor] == '\\' && escapable_punctuation?(contents[cursor + 1])
        target << contents[cursor + 1]
        cursor += 2
        next
      end

      if contents[cursor] == '>' && !escaped?(contents, cursor)
        return nil if target.empty?

        return { target: target, raw: contents[index..cursor], end_index: cursor + 1 }
      end
      return nil if contents[cursor] == '<'

      target << contents[cursor]
      cursor += 1
    end
    nil
  end

  def parse_bare_destination(contents, index, stop_at_space:, allow_end: false)
    cursor = index
    depth = 0
    target = +''

    while cursor < contents.length
      char = contents[cursor]
      if char == '\\' && escapable_punctuation?(contents[cursor + 1])
        target << contents[cursor + 1]
        cursor += 2
        next
      end

      if char == '('
        depth += 1
      elsif char == ')'
        break if depth.zero?

        depth -= 1
      elsif char.match?(/[ \t]/)
        break if stop_at_space && depth.zero?

        return nil
      elsif char == "\n"
        break
      end

      target << char
      cursor += 1
    end

    return nil if target.empty? || depth.positive?
    return nil if !allow_end && cursor >= contents.length

    { target: target, raw: target, end_index: cursor }
  end

  def parse_optional_title(contents, index)
    opener = contents[index]
    closer = { '"' => '"', "'" => "'", '(' => ')' }[opener]
    return nil unless closer

    cursor = index + 1
    while cursor < contents.length
      return nil if blank_line_after_line_ending?(contents, cursor)
      return cursor + 1 if contents[cursor] == closer && !escaped?(contents, cursor)

      cursor += 1
    end
    nil
  end

  def reference_definition_next_index(lines, next_index, destination_line, end_index)
    remainder_index = skip_spaces(destination_line, end_index)
    if remainder_index >= destination_line.length
      title_line = reference_continuation_line(lines[next_index])
      title_start = reference_title_start_index(title_line)
      return next_index unless title_start

      return reference_title_next_index(lines, next_index + 1, title_line, title_start)
    end

    reference_title_next_index(lines, next_index, destination_line, remainder_index)
  end

  def reference_title_start_index(line)
    return nil unless line

    indent = line[/\A {1,3}/]&.length
    return nil unless indent&.positive?

    { '"' => '"', "'" => "'", '(' => ')' }.key?(line[indent]) ? indent : nil
  end

  def reference_title_next_index(lines, next_index, title_line, start_index)
    opener = title_line[start_index]
    closer = { '"' => '"', "'" => "'", '(' => ')' }[opener]
    return nil unless closer

    line = title_line
    cursor = start_index + 1
    loop do
      while cursor < line.length
        if line[cursor] == closer && !escaped?(line, cursor)
          return nil unless skip_spaces(line, cursor + 1) >= line.length

          return next_index
        end

        cursor += 1
      end

      return nil if next_index >= lines.length

      line = reference_continuation_line(lines[next_index])
      return nil if line.nil? || line.strip.empty?

      next_index += 1
      cursor = 0
    end
  end

  def link_for_target(target, raw_target)
    target = CGI.unescapeHTML(target)
    return nil if target.start_with?('//') || target.match?(SCHEME_PATTERN)

    path_and_query, raw_fragment = target.split('#', 2)
    raw_path = path_and_query.split('?', 2).first || ''
    {
      raw: raw_target,
      path: percent_decode(raw_path),
      fragment: raw_fragment.nil? ? nil : percent_decode(raw_fragment)
    }
  rescue ArgumentError => error
    { raw: raw_target, error: error.message }
  end

  def next_link_text_opener(contents, index)
    cursor = index
    while cursor < contents.length
      if contents[cursor] == '[' && !escaped?(contents, cursor)
        return cursor
      elsif contents[cursor] == '!' && contents[cursor + 1] == '[' && !escaped?(contents, cursor)
        return cursor
      end

      cursor += 1
    end
    nil
  end

  def matching_bracket(contents, index)
    depth = 1
    cursor = index

    while cursor < contents.length
      if contents[cursor] == '[' && !escaped?(contents, cursor)
        depth += 1
      elsif contents[cursor] == ']' && !escaped?(contents, cursor)
        depth -= 1
        return cursor if depth.zero?
      end

      cursor += 1
    end
    nil
  end

  def skip_spaces(contents, index)
    index += 1 while [' ', "\t"].include?(contents[index])
    index
  end

  def skip_link_spacing(contents, index)
    index = skip_spaces(contents, index)
    if contents[index] == "\r" && contents[index + 1] == "\n"
      index = skip_spaces(contents, index + 2)
    elsif contents[index] == "\n"
      index = skip_spaces(contents, index + 1)
    end
    index
  end

  def blank_line_after_line_ending?(contents, index)
    if contents[index] == "\r" && contents[index + 1] == "\n"
      cursor = index + 2
    elsif contents[index] == "\n"
      cursor = index + 1
    else
      return false
    end

    cursor += 1 while [' ', "\t"].include?(contents[cursor])
    contents[cursor] == "\n" || (contents[cursor] == "\r" && contents[cursor + 1] == "\n")
  end

  def normalize_reference_label(label)
    label = CGI.unescapeHTML(unescape_markdown_punctuation(label))
    label.gsub(/[ \t\r\n]+/, ' ').strip.downcase
  end

  def valid_reference_label?(label)
    return false if normalize_reference_label(label).empty?
    return false if label.length > 999

    cursor = 0
    while cursor < label.length
      return false if ['[', ']'].include?(label[cursor]) && !escaped?(label, cursor)

      cursor += 1
    end
    true
  end

  def footnote_label?(label)
    label.start_with?('^')
  end

  def unescape_markdown_punctuation(text)
    unescaped = +''
    cursor = 0
    while cursor < text.length
      if text[cursor] == '\\' && escapable_punctuation?(text[cursor + 1])
        unescaped << text[cursor + 1]
        cursor += 2
        next
      end

      unescaped << text[cursor]
      cursor += 1
    end
    unescaped
  end

  def escapable_punctuation?(character)
    character&.match?(ESCAPABLE_PUNCTUATION_PATTERN)
  end

  def escaped?(contents, index)
    backslashes = 0
    cursor = index - 1
    while cursor >= 0 && contents[cursor] == '\\'
      backslashes += 1
      cursor -= 1
    end
    backslashes.odd?
  end

  def mask_html_comments(contents)
    masked = +''
    cursor = 0

    while cursor < contents.length
      comment_index = contents.index('<!--', cursor)
      code_span = next_matched_code_span(contents, cursor)

      if code_span && (comment_index.nil? || code_span[0] < comment_index)
        masked << contents[cursor...code_span[1]]
        cursor = code_span[1]
        next
      end

      unless comment_index
        masked << contents[cursor..]
        break
      end

      masked << contents[cursor...comment_index]
      comment_end = html_comment_end(contents, comment_index + 4)
      if comment_end
        comment_end_index = comment_end[0] + comment_end[1]
        masked << mask_preserving_newlines(contents[comment_index...comment_end_index])
        cursor = comment_end_index
      else
        masked << mask_preserving_newlines(contents[comment_index..])
        cursor = contents.length
      end
    end

    masked
  end

  def html_comment_end(contents, start_index)
    normal_end = contents.index('-->', start_index)
    bang_end = contents.index('--!>', start_index)
    return nil unless normal_end || bang_end
    return [normal_end, 3] if normal_end && (!bang_end || normal_end <= bang_end)

    [bang_end, 4]
  end

  def mask_raw_html_blocks(contents)
    masked = +''
    raw_html_end = nil
    raw_html_until_blank = false
    block_start = true

    contents.lines.each do |line|
      content = line.chomp
      html_content = raw_html_line_content(content, block_start)
      if raw_html_end
        masked << mask_preserving_newlines(line)
        raw_html_end = nil if raw_html_block_closed?(html_content, raw_html_end)
        block_start = true
        next
      end

      if raw_html_until_blank
        if html_content.strip.empty?
          masked << line
          raw_html_until_blank = false
          block_start = true
        else
          masked << mask_preserving_newlines(line)
          block_start = true
        end
        next
      end

      raw_html_block = raw_html_block_start(content, block_start)
      if raw_html_block
        masked << mask_preserving_newlines(line)
        if raw_html_block[:end_text] || raw_html_block[:end_texts] || raw_html_block[:end_tag]
          raw_html_end = raw_html_block
          raw_html_end = nil if raw_html_block_closed?(html_content, raw_html_end)
        else
          raw_html_until_blank = true
        end
        block_start = true
        next
      end

      masked << line
      block_start = reference_definition_can_follow_line?(reference_continuation_line(content).to_s,
                                                          block_start)
    end

    masked
  end

  def raw_html_block_start(content, block_start)
    line = raw_html_line_content(content, block_start)
    start = line[/\A {0,3}/].length
    return nil unless line[start] == '<'

    html = line[start..].to_s
    tag_opening = html.match(/\A<(?<tag>script|pre|style|textarea)(?:[ \t>\/]|\z)/i)
    return { end_tag: tag_opening[:tag].downcase } if tag_opening
    return { end_texts: ['-->', '--!>'] } if html.start_with?('<!--')
    return { end_text: '?>' } if html.start_with?('<?')
    return { end_text: '>' } if html.match?(/\A<![A-Z]/)
    return { end_text: ']]>' } if html.start_with?('<![CDATA[')
    return { until_blank: true } if html.match?(COMMONMARK_HTML_BLOCK_PATTERN)
    return { until_blank: true } if block_start && complete_open_or_closing_tag_line?(html)

    nil
  end

  def raw_html_block_closed?(content, end_condition)
    if end_condition[:end_tag]
      raw_html_end_tag?(content, end_condition[:end_tag])
    elsif end_condition[:end_texts]
      end_condition[:end_texts].any? { |text| content.include?(text) }
    elsif end_condition[:end_text]
      content.include?(end_condition[:end_text])
    else
      false
    end
  end

  def raw_html_end_tag?(content, tag)
    lower_content = content.downcase
    needle = "</#{tag}"
    index = lower_content.index(needle)
    while index
      remainder = lower_content[(index + needle.length)..].to_s.lstrip
      return true if remainder.start_with?('>')

      index = lower_content.index(needle, index + 1)
    end

    false
  end

  def raw_html_line_content(content, block_start = true)
    line = reference_continuation_line(content).to_s
    start = line[/\A {0,3}/].length
    marker = line[start..].to_s.match(/\A(?<marker>[-+*]|\d{1,9}[.)])(?:[ \t]+|\z)/)
    return line unless marker
    return line unless container_marker_can_interrupt_paragraph?(marker[:marker], block_start)

    line[(start + marker[0].length)..].to_s
  end

  def container_marker_can_interrupt_paragraph?(marker, block_start)
    return true if block_start
    return true if ['-', '+', '*'].include?(marker)

    marker.match?(/\A1[.)]\z/)
  end

  def complete_open_or_closing_tag_line?(line)
    stripped = line.strip
    return false unless stripped.start_with?('<') && stripped.end_with?('>')

    cursor = 1
    closing = stripped[cursor] == '/'
    cursor += 1 if closing

    tag_end = scan_tag_name_end(stripped, cursor)
    return false unless tag_end

    cursor = tag_end
    if closing
      cursor += 1 while [' ', "\t"].include?(stripped[cursor])
      return cursor == stripped.length - 1
    end

    body = stripped[cursor...(stripped.length - 1)].to_s.rstrip
    body = body[0...-1].to_s.rstrip if body.end_with?('/')
    valid_html_attributes?(body)
  end

  def scan_tag_name_end(text, cursor)
    return nil unless ascii_letter?(text[cursor])

    cursor += 1
    while cursor < text.length && (ascii_letter?(text[cursor]) || ascii_digit?(text[cursor]) || text[cursor] == '-')
      cursor += 1
    end
    cursor
  end

  def valid_html_attributes?(text)
    cursor = 0
    loop do
      cursor += 1 while [' ', "\t"].include?(text[cursor])
      return true if cursor >= text.length

      cursor = scan_attribute_name_end(text, cursor)
      return false unless cursor

      cursor += 1 while [' ', "\t"].include?(text[cursor])
      next unless text[cursor] == '='

      cursor += 1
      cursor += 1 while [' ', "\t"].include?(text[cursor])
      cursor = scan_attribute_value_end(text, cursor)
      return false unless cursor
    end
  end

  def scan_attribute_name_end(text, cursor)
    return nil unless ascii_letter?(text[cursor]) || ['_', ':'].include?(text[cursor])

    cursor += 1
    while cursor < text.length &&
          (ascii_letter?(text[cursor]) || ascii_digit?(text[cursor]) || ['_', '.', ':', '-'].include?(text[cursor]))
      cursor += 1
    end
    cursor
  end

  def scan_attribute_value_end(text, cursor)
    quote = text[cursor]
    if ['"', "'"].include?(quote)
      cursor += 1
      while cursor < text.length
        return cursor + 1 if text[cursor] == quote

        cursor += 1
      end
      return nil
    end

    return nil if cursor >= text.length
    while cursor < text.length && ![' ', "\t"].include?(text[cursor])
      return nil if ['"', "'", '=', '<', '>', '`'].include?(text[cursor])

      cursor += 1
    end
    cursor
  end

  def ascii_letter?(character)
    character&.match?(/[A-Za-z]/)
  end

  def ascii_digit?(character)
    character&.match?(/[0-9]/)
  end

  def next_matched_code_span(contents, start_index)
    search_from = start_index
    while (opening = next_backtick_run(contents, search_from))
      opening_index, opening_length = opening
      if escaped_opening_backtick?(contents, opening_index)
        search_from = opening_index + opening_length
        next
      end

      closing_index = matching_backtick_run(contents, opening_index + opening_length, opening_length)
      return [opening_index, closing_index + opening_length] if closing_index

      search_from = opening_index + opening_length
    end
    nil
  end

  def mask_preserving_newlines(contents)
    contents.gsub(/[^\n]/, ' ')
  end

  def mask_inline_code_spans(contents)
    masked = +''
    cursor = 0
    search_from = 0

    while (opening = next_backtick_run(contents, search_from))
      opening_index, opening_length = opening
      if escaped_opening_backtick?(contents, opening_index)
        search_from = opening_index + opening_length
        next
      end

      closing_index = matching_backtick_run(contents, opening_index + opening_length, opening_length)
      unless closing_index
        search_from = opening_index + opening_length
        next
      end

      masked << contents[cursor...opening_index]
      masked << mask_preserving_newlines(contents[opening_index...(closing_index + opening_length)])
      cursor = closing_index + opening_length
      search_from = cursor
    end

    masked << contents[cursor..]
  end

  def next_backtick_run(contents, start_index)
    index = contents.index('`', start_index)
    return nil unless index

    [index, backtick_run_length(contents, index)]
  end

  def matching_backtick_run(contents, start_index, expected_length)
    search_from = start_index
    while (run = next_backtick_run(contents, search_from))
      index, length = run
      return index if length == expected_length

      search_from = index + length
    end
    nil
  end

  def backtick_run_length(contents, index)
    length = 0
    length += 1 while contents[index + length] == '`'
    length
  end

  def escaped_opening_backtick?(contents, index)
    backslashes = 0
    cursor = index - 1
    while cursor >= 0 && contents[cursor] == '\\'
      backslashes += 1
      cursor -= 1
    end
    backslashes.odd?
  end

  def heading_anchors(contents)
    used = {}
    anchors = []
    markdown_segments(contents).each do |segment|
      setext_candidate = nil
      mask_html_comments(segment).lines(chomp: true).each do |content|
        setext_underline = content.match(/\A {0,3}(?:=+|-+)[ \t]*\z/)
        if setext_underline && setext_candidate
          append_heading_anchor(anchors, used, setext_candidate)
          setext_candidate = nil
          next
        end

        match = content.match(/\A {0,3}\#{1,6}\s+(.+?)\s*\#*\s*\z/)
        if match
          append_heading_anchor(anchors, used, match[1])
          setext_candidate = nil
          next
        end

        setext_candidate = setext_heading_candidate(content)
      end
    end

    anchors
  end

  def markdown_segments(contents)
    projection = fence_aware_lines(contents).map { |line| line || '' }.join("\n")
    projection.empty? ? [] : [projection]
  end

  def fence_aware_lines(contents)
    return enum_for(__method__, contents) unless block_given?

    fence_marker = nil
    fence_length = nil
    indented_code = false
    block_start = true
    contents.lines.each do |line|
      content = line.chomp
      block_content = raw_html_line_content(content, block_start)
      if fence_marker
        closing_fence = /\A {0,3}#{Regexp.escape(fence_marker)}{#{fence_length},}[ \t]*\z/
        if block_content.match?(closing_fence)
          fence_marker = nil
          fence_length = nil
        end
        yield nil
        block_start = true
        next
      end

      if indented_code
        if block_content.strip.empty? || indented_code_line?(block_content)
          yield nil
          block_start = true
          next
        end

        indented_code = false
      end

      if block_start && indented_code_line?(block_content)
        indented_code = true
        yield nil
        block_start = true
        next
      end

      opening_fence = block_content.match(/\A {0,3}(`{3,}|~{3,})(.*)\z/)
      if opening_fence &&
         (opening_fence[1].start_with?('~') || !opening_fence[2].include?('`'))
        fence_marker = opening_fence[1][0]
        fence_length = opening_fence[1].length
        yield nil
        block_start = true
        next
      end

      yield content
      block_start = reference_definition_can_follow_line?(reference_continuation_line(content).to_s,
                                                          block_start)
    end
  end

  def append_heading_anchor(anchors, used, heading)
    base = heading_slug(heading)
    return if base.empty?

    anchor = base
    suffix = 0
    while used[anchor]
      suffix += 1
      anchor = "#{base}-#{suffix}"
    end
    used[anchor] = true
    anchors << anchor
  end

  def setext_heading_candidate(content)
    return nil if content.empty? || content.match?(/\A(?: {4}| {0,3}\t)/)
    return nil if content.match?(/\A {0,3}(?:=+|-+)[ \t]*\z/)

    candidate = content.sub(/\A {0,3}/, '').strip
    return nil if candidate.match?(/\A(?:[-+*]|\d+[.)])(?:[ \t]+|\z)/)
    return nil if candidate.match?(/\A>(?:[ \t]+|\z)/)

    candidate.empty? ? nil : candidate
  end

  def heading_slug(heading)
    text = heading.gsub(/!?(?:\[([^\]]+)\])\([^)]*\)/, '\\1')
    text = CGI.unescapeHTML(strip_inline_html_tags_for_slug(text))
    text = text.gsub(/(?<!\w)__([^_\n]+)__(?!\w)/, '\\1')
    text = text.gsub(/(?<!\w)_([^_\n]+)_(?!\w)/, '\\1')
    text = text.downcase.strip
    text = text.gsub(/[^\p{L}\p{N}\p{M}\-_\s]/u, '')
    text.gsub(' ', '-').gsub(/[[:space:]]/, '')
  end

  def strip_inline_html_tags_for_slug(text)
    stripped = +''
    cursor = 0
    while cursor < text.length
      if text[cursor] == '<'
        close = text.index('>', cursor + 1)
        if close
          cursor = close + 1
          next
        end
      end

      stripped << text[cursor]
      cursor += 1
    end
    stripped
  end

  def percent_decode(value)
    raise ArgumentError, 'invalid percent escape' if value.match?(INVALID_ESCAPE_PATTERN)

    decoded = URI::DEFAULT_PARSER.unescape(value)
    raise ArgumentError, 'decoded value has invalid encoding' unless decoded.valid_encoding?
    raise ArgumentError, 'decoded value contains null byte' if decoded.include?("\0")

    decoded
  end

  def exact_regular_file?(target, root)
    return false unless exact_path?(target, root)

    target.file? && !target.symlink?
  rescue ArgumentError
    false
  end

  def exact_path?(target, root)
    relative = target.relative_path_from(root).to_s
    return true if relative == '.'

    current = root
    relative.split(File::SEPARATOR).each do |component|
      return false unless current.directory?
      return false unless current.children.any? { |child| child.basename.to_s == component }

      current = current.join(component)
      return false if current.symlink?
    end
    true
  rescue ArgumentError
    false
  end
end
