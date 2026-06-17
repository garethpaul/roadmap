#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'uri'
require 'cgi'

module MarkdownLinkContract
  LINK_PATTERN = /!?\[[^\]]*\]\((?:<([^>\n]*)>|([^)\s]+))(?:\s+["'][^"']*["'])?\)/.freeze
  SCHEME_PATTERN = /\A[a-z][a-z0-9+.-]*:/i.freeze
  INVALID_ESCAPE_PATTERN = /%(?![0-9a-f]{2})/i.freeze

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
      unless within_repository && target.file? && !target.symlink?
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
    visible_contents = mask_inline_code_spans(mask_html_comments(contents))
    visible_contents.scan(LINK_PATTERN).filter_map do |angle_target, bare_target|
      target = angle_target.nil? ? bare_target : angle_target
      raw_target = angle_target.nil? ? bare_target : "<#{angle_target}>"
      next if target.start_with?('//') || target.match?(SCHEME_PATTERN)

      path_and_query, raw_fragment = target.split('#', 2)
      raw_path = path_and_query.split('?', 2).first || ''
      begin
        {
          raw: raw_target,
          path: percent_decode(raw_path),
          fragment: raw_fragment.nil? ? nil : percent_decode(raw_fragment)
        }
      rescue ArgumentError => error
        { raw: raw_target, error: error.message }
      end
    end
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
      comment_end = contents.index('-->', comment_index + 4)
      if comment_end
        comment_end += 3
        masked << mask_preserving_newlines(contents[comment_index...comment_end])
        cursor = comment_end
      else
        masked << mask_preserving_newlines(contents[comment_index..])
        cursor = contents.length
      end
    end

    masked
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

      masked << contents[cursor...opening_index] << "\n"
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
    contents.lines.each do |line|
      content = line.chomp
      if fence_marker
        closing_fence = /\A {0,3}#{Regexp.escape(fence_marker)}{#{fence_length},}[ \t]*\z/
        if content.match?(closing_fence)
          fence_marker = nil
          fence_length = nil
        end
        yield nil
        next
      end

      opening_fence = content.match(/\A {0,3}(`{3,}|~{3,})(.*)\z/)
      if opening_fence &&
         (opening_fence[1].start_with?('~') || !opening_fence[2].include?('`'))
        fence_marker = opening_fence[1][0]
        fence_length = opening_fence[1].length
        yield nil
        next
      end

      yield content
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
    text = CGI.unescapeHTML(text.gsub(/<[^>]*>/, ''))
    text = text.gsub(/(?<!\w)__([^_\n]+)__(?!\w)/, '\\1')
    text = text.gsub(/(?<!\w)_([^_\n]+)_(?!\w)/, '\\1')
    text = text.downcase.strip
    text = text.gsub(/[^\p{L}\p{N}\p{M}\-_\s]/u, '')
    text.gsub(' ', '-').gsub(/[[:space:]]/, '')
  end

  def percent_decode(value)
    raise ArgumentError, 'invalid percent escape' if value.match?(INVALID_ESCAPE_PATTERN)

    URI::DEFAULT_PARSER.unescape(value)
  end
end
