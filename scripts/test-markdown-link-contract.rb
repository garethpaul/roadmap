#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative 'markdown-link-contract'

class MarkdownLinkContractTest < Minitest::Test
  def with_docs
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      source = root.join('README.md')
      target = root.join('GUIDE.md')
      target.write("# Guide\n\n## Setup & Usage\n\n## Repeat\n\n## Repeat\n")
      yield root, source, target
    end
  end

  def test_accepts_local_paths_same_file_cross_file_and_duplicate_anchors
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        # Home

        [Guide](GUIDE.md)
        [Setup](GUIDE.md#setup--usage)
        [Second repeat](GUIDE.md#repeat-1)
        [Home](#home)
        [External](https://example.com/missing#anchor)
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_rejects_missing_anchor_and_non_markdown_fragment
    with_docs do |root, source, _target|
      root.join('image.svg').write('<svg/>')
      source.write("[Missing](GUIDE.md#missing)\n[Image](image.svg#root)\n")

      failures = MarkdownLinkContract.validate(source, root)
      assert_includes failures, 'references missing Markdown anchor "missing" in "GUIDE.md"'
      assert_includes failures, 'references fragment "root" on non-Markdown target "image.svg"'
    end
  end

  def test_rejects_missing_unsafe_and_malformed_targets
    with_docs do |root, source, _target|
      source.write("[Missing](MISSING.md)\n[Escape](../outside.md)\n[Malformed](GUIDE.md#bad%2)\n")

      failures = MarkdownLinkContract.validate(source, root)
      assert failures.any? { |failure| failure.include?('MISSING.md') }
      assert failures.any? { |failure| failure.include?('../outside.md') }
      assert failures.any? { |failure| failure.include?('invalid percent escape') }
    end
  end

  def test_preserves_titles_angle_targets_and_percent_decoding
    with_docs do |root, source, _target|
      root.join('space name.md').write("# Encoded Heading\n")
      source.write('[Encoded](<space%20name.md#encoded-heading> "Title")')

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_literal_spaces_in_angle_destinations
    with_docs do |root, source, _target|
      root.join('design notes.md').write("# Review Notes\n")
      root.join('diagram file.svg').write('<svg/>')
      source.write(<<~MARKDOWN)
        [Review](<design notes.md#review-notes> "Design review")
        [Missing](<missing notes.md>)
        [Escape](<../outside notes.md>)
        [Missing anchor](<design notes.md#missing>)
        [Non-Markdown fragment](<diagram file.svg#root>)
        [External](<https://example.com/design notes>)
        [Protocol relative](<//example.com/design notes>)
      MARKDOWN

      failures = MarkdownLinkContract.validate(source, root)
      assert_equal [
        'references missing or unsafe local target "missing notes.md"',
        'references missing or unsafe local target "../outside notes.md"',
        'references missing Markdown anchor "missing" in "design notes.md"',
        'references fragment "root" on non-Markdown target "diagram file.svg"'
      ], failures
    end
  end

  def test_rejects_reference_style_local_links
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Guide][mixed case]
        [Collapsed Reference][]
        [Shortcut Reference]
        [External][external]

        [Mixed Case]: GUIDE.md#setup--usage
        [collapsed reference]: MISSING-COLLAPSED.md
        [shortcut reference]: <missing shortcut.md>
        [external]: https://example.com/missing
      MARKDOWN

      assert_equal [
        'references missing or unsafe local target "MISSING-COLLAPSED.md"',
        'references missing or unsafe local target "missing shortcut.md"'
      ], MarkdownLinkContract.validate(source, root)
    end
  end

  def test_reference_definitions_keep_the_first_label
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [External first][duplicate]

        [duplicate]: https://example.com/guide
        [duplicate]: MISSING.md
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_reference_definitions_with_invalid_trailing_text
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Shortcut Reference]

        [shortcut reference]: MISSING.md trailing text
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_multiline_reference_destinations
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Shortcut Reference]

        [shortcut reference]:
          MISSING.md
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_unindented_multiline_reference_destinations
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Shortcut Reference]

        [shortcut reference]:
        MISSING.md
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_reference_definitions_after_indented_code_blocks
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
            code
        [target]: MISSING.md

        [Doc][target]
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_reference_definitions_after_indented_paragraph_continuations
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph
            [target]: MISSING.md

        [Doc][target]
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_reference_definitions_inside_paragraphs
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph text
        [shortcut reference]: MISSING.md

        [Shortcut Reference]
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_reference_definitions_after_completed_blocks
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        # Heading
        [heading ref]: MISSING-HEADING.md

        ---
        [rule ref]: MISSING-RULE.md

        [Heading Ref]
        [Rule Ref]
      MARKDOWN

      assert_equal [
        'references missing or unsafe local target "MISSING-HEADING.md"',
        'references missing or unsafe local target "MISSING-RULE.md"'
      ], MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_reference_definitions_after_inline_code_paragraphs
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph `code`
        [shortcut reference]: MISSING.md

        [Shortcut Reference]
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_invalid_reference_labels
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [foo [bar]]: MISSING-NESTED.md
        [ ]: MISSING-BLANK.md

        [foo [bar]]
        [ ]
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_reference_definitions_inside_block_containers
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Block quote][quoted]
        [List item][listed]

        > [quoted]: MISSING-BLOCK.md
        - [listed]: MISSING-LIST.md
      MARKDOWN

      assert_equal [
        'references missing or unsafe local target "MISSING-BLOCK.md"',
        'references missing or unsafe local target "MISSING-LIST.md"'
      ], MarkdownLinkContract.validate(source, root)
    end
  end

  def test_non_one_ordered_reference_definition_does_not_interrupt_paragraphs
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph
        2. [target]: MISSING.md

        [target]
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_one_ordered_reference_definition_can_interrupt_paragraphs
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph
        1. [target]: MISSING.md

        [target]
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_reference_definitions_in_new_container_blocks
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph text
        > [quoted]: MISSING-BLOCK.md
        Another paragraph
        - [listed]: MISSING-LIST.md

        [quoted]
        [listed]
      MARKDOWN

      assert_equal [
        'references missing or unsafe local target "MISSING-BLOCK.md"',
        'references missing or unsafe local target "MISSING-LIST.md"'
      ], MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_links_and_reference_definitions_inside_raw_html_blocks
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        <script>
        [ref]: MISSING-REF.md
        [Hidden](MISSING-HIDDEN.md)
        </script>

        [ref]
        [Visible](MISSING-VISIBLE.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING-VISIBLE.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_reference_link_uses_inside_commonmark_raw_html_blocks
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        <div>
        [Hidden][target]
        </div>

        [target]: MISSING.md
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_reference_definitions_inside_commonmark_raw_html_blocks
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Doc][target]

        <div>
        [target]: MISSING-DIV.md
        </div>

        <textarea>
        [target]: MISSING-TEXTAREA.md
        </textarea>
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_raw_html_blocks_inside_block_containers
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        > <div>
        > [Hidden](MISSING-BLOCKQUOTE.md)
        > </div>

        - <textarea>
          [target]: MISSING-LIST.md
          </textarea>

        [target]
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_type7_html_blocks_do_not_interrupt_paragraphs
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph
        <x-tag>
        [Missing](MISSING.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_type7_html_blocks_at_block_start
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        <x-tag>
        [Hidden](MISSING.md)
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_type7_html_blocks_allow_quoted_attribute_punctuation
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        <x-tag data-title="literal > marker" data-less='literal < marker' data-code="`tick`">
        [Hidden](MISSING-HIDDEN.md)

        [Visible](MISSING-VISIBLE.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING-VISIBLE.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_malformed_type7_html_attributes_do_not_hide_links
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        <x-tag data-title=bad"value>
        [Visible](MISSING.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_non_one_ordered_html_blocks_do_not_interrupt_paragraphs
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph
        2. <div>
        [Missing](MISSING.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_reference_definitions_with_multiline_titles
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Multiline title][ref]

        [ref]: MISSING.md "first
        second"
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_unescapes_reference_label_punctuation
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Escaped][ref!]

        [ref\\!]: MISSING.md
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_decodes_reference_label_entities
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Entity][ref&]

        [ref&amp;]: MISSING.md
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_decodes_destination_entities
    with_docs do |root, source, _target|
      root.join('A&B.md').write("# Entity Path\n")
      source.write(<<~MARKDOWN)
        [Inline](A&amp;B.md)
        [Reference][entity]
        [entity]: <A&amp;B.md>
        [Missing](missing&amp;file.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "missing&file.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_parses_bare_destinations_with_balanced_parentheses
    with_docs do |root, source, _target|
      root.join('file(1).md').write("# Title\n")
      source.write("[File](file(1).md)\n[Missing](missing(1).md)\n")

      assert_equal ['references missing or unsafe local target "missing(1).md"'],
                   MarkdownLinkContract.validate(source, root)
      assert_equal %w[file(1).md missing(1).md],
                   MarkdownLinkContract.links(source.read).map { |link| link[:path] }
    end
  end

  def test_unescapes_backslash_escaped_destination_characters
    with_docs do |root, source, _target|
      root.join('file(1).md').write("# File\n")
      source.write("[File](file\\(1\\).md)\n")

      assert_empty MarkdownLinkContract.validate(source, root)
      assert_equal ['file(1).md'],
                   MarkdownLinkContract.links(source.read).map { |link| link[:path] }
    end
  end

  def test_preserves_backslashes_before_non_escapable_destination_characters
    with_docs do |root, source, _target|
      root.join('foobar.md').write("# Wrong Target\n")
      source.write("[Backslash](foo\\bar.md)\n")

      assert_equal ['references missing or unsafe local target "foo\\\\bar.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_bare_destinations_with_unescaped_spaces
    with_docs do |root, source, _target|
      source.write("[Not a rendered link](missing(foo bar).md)\n")

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_inline_links_inside_indented_code_blocks
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
            [Hidden](MISSING.md)
        [Visible](MISSING-VISIBLE.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING-VISIBLE.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_headings_inside_indented_code_blocks
    assert_equal ['visible'],
                 MarkdownLinkContract.heading_anchors("# Visible\n\n    # Hidden\n")
  end

  def test_ignores_indented_code_inside_block_containers
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        >     [Hidden](MISSING-BLOCKQUOTE.md)

        - item

              [Hidden](MISSING-LIST.md)
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_fenced_code_inside_block_containers
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        > ```
        > [Hidden](MISSING-BLOCKQUOTE.md)
        > ```

        - ```
          [Hidden](MISSING-LIST.md)
          ```
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_non_one_ordered_fences_do_not_interrupt_paragraphs
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph
        2. ```
        [Missing](MISSING.md)
        ```
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_inline_links_inside_indented_paragraph_continuations
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        Paragraph
            [Missing](MISSING.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_inline_link_titles_after_line_breaks
    with_docs do |root, source, _target|
      source.write("[Missing](MISSING.md\n \"Title\")\n")

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_inline_destinations_after_line_breaks
    with_docs do |root, source, _target|
      source.write("[Missing](\nMISSING.md)\n[Angle](\n<MISSING.svg>)\n")

      assert_equal [
        'references missing or unsafe local target "MISSING.md"',
        'references missing or unsafe local target "MISSING.svg"'
      ], MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_inline_link_titles_with_line_endings
    with_docs do |root, source, _target|
      source.write("[Missing](MISSING.md \"first\nsecond\")\n")

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_angle_destinations_without_title_spacing
    with_docs do |root, source, _target|
      source.write("[Not a rendered link](<MISSING.md>\"Title\")\n")

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_angle_destinations_with_unescaped_less_than
    with_docs do |root, source, _target|
      source.write("[Not a rendered link](<foo<bar.md>)\n")

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_inline_link_titles_with_blank_lines
    with_docs do |root, source, _target|
      source.write("[Not a rendered link](MISSING.md \"first\n\nsecond\")\n")

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_nested_images_inside_link_text
    with_docs do |root, source, _target|
      source.write("[![Diagram](MISSING.svg)](https://example.com/diagram)\n")

      assert_equal ['references missing or unsafe local target "MISSING.svg"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_validates_rendered_links_inside_literal_brackets
    with_docs do |root, source, _target|
      source.write("[See [Missing](MISSING.md)]\n")

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_nested_links_inside_link_text
    with_docs do |root, source, _target|
      source.write("[See [Missing](MISSING.md)](https://example.com)\n")

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_gfm_footnotes_as_reference_links
    with_docs do |root, source, _target|
      source.write("[^note]\n\n[^note]: MISSING.md\n")

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_masks_reference_title_continuation_lines
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Guide][guide]

        [guide]: GUIDE.md
          "[missing]"
        [missing]: MISSING.md
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_rejects_decoded_null_bytes_without_crashing
    with_docs do |root, source, _target|
      source.write("[Null](GUIDE%00.md)\n")

      failures = MarkdownLinkContract.validate(source, root)
      refute_empty failures
      assert failures.any? { |failure| failure.include?('null byte') }, failures.inspect
    end
  end

  def test_rejects_invalid_percent_decoded_encoding_without_crashing
    with_docs do |root, source, _target|
      source.write("[Bad encoding](GUIDE%FF.md)\n")

      failures = MarkdownLinkContract.validate(source, root)
      refute_empty failures
      assert failures.any? { |failure| failure.include?('invalid encoding') }, failures.inspect
    end
  end

  def test_rejects_wrong_case_local_paths
    with_docs do |root, source, _target|
      root.join('Guide.md').write("# Guide\n")
      source.write("[Wrong case](guide.md)\n")

      assert_equal ['references missing or unsafe local target "guide.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_rejects_targets_reached_through_symlinked_directories
    with_docs do |root, source, _target|
      Dir.mktmpdir do |outside|
        File.write(File.join(outside, 'outside.md'), "# Outside\n")
        File.symlink(outside, root.join('linked'))
        source.write("[Outside](linked/outside.md)\n")

        assert_equal ['references missing or unsafe local target "linked/outside.md"'],
                     MarkdownLinkContract.validate(source, root)
      end
    end
  end

  def test_matches_documented_github_heading_normalization
    heading = "This'll be a _Helpful_ Section About the Greek Letter Θ!"

    assert_equal 'thisll-be-a-helpful-section-about-the-greek-letter-θ',
                 MarkdownLinkContract.heading_slug(heading)
    assert_equal 'tabbedheading', MarkdownLinkContract.heading_slug("Tabbed\tHeading")
    assert_equal '-emoji', MarkdownLinkContract.heading_slug('😄 emoji')
    assert_equal 'trimmed-heading', MarkdownLinkContract.heading_slug('  Trimmed Heading  ')
    assert_equal 'helpful-fish--chips',
                 MarkdownLinkContract.heading_slug('<em>Helpful</em> Fish &amp; Chips')
    assert_equal 'ok_hand-single', MarkdownLinkContract.heading_slug(':ok_hand: Single')
    assert_equal %w[repeat repeat-1 repeat-2],
                 MarkdownLinkContract.heading_anchors("## Repeat\n## Repeat-1\n## Repeat\n")
  end

  def test_ignores_atx_headings_inside_backtick_and_tilde_fences
    markdown = <<~MARKDOWN
      # Visible

       ```ruby
      # Hidden Backtick
       ```

      ~~~~ text
      ## Hidden Tilde
      ~~~~~

      ## Visible Again
    MARKDOWN

    assert_equal %w[visible visible-again], MarkdownLinkContract.heading_anchors(markdown)
  end

  def test_requires_matching_fence_marker_and_minimum_closing_length
    markdown = <<~MARKDOWN
      ````
      # Hidden
      ```
      ## Still Hidden After Short Close
      ~~~~
      ### Still Hidden After Wrong Marker
      `````
      # Visible After Valid Close
      ~~~
      ## Hidden In Unclosed Fence
    MARKDOWN

    assert_equal ['visible-after-valid-close'], MarkdownLinkContract.heading_anchors(markdown)
  end

  def test_requires_three_markers_and_valid_backtick_info
    markdown = <<~MARKDOWN
      ``
      # Two Backticks
      ``
      ~~
      ## Two Tildes
      ~~
      ```ruby`invalid
      ### Backtick In Info
      ```
    MARKDOWN

    assert_equal ['two-backticks', 'two-tildes', 'backtick-in-info'],
                 MarkdownLinkContract.heading_anchors(markdown)
  end

  def test_ignores_inline_links_and_images_inside_matching_fences
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        [Guide](GUIDE.md)

        ```markdown
        [Missing example](MISSING.md)
        ![Missing image](missing.svg)
        ```

        ~~~ text
        [Escaping example](../outside.md)
        ~~~

        [Visible missing](VISIBLE-MISSING.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "VISIBLE-MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_requires_matching_marker_and_closing_length_before_links_resume
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        ````markdown
        [Hidden](MISSING-ONE.md)
        ```
        [Still hidden after short close](MISSING-TWO.md)
        ~~~~
        [Still hidden after wrong marker](MISSING-THREE.md)
        `````
        [Visible](VISIBLE-MISSING.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "VISIBLE-MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_fenced_link_boundaries_do_not_join_surrounding_markdown
    markdown = <<~MARKDOWN
      Candidate
      ```text
      [Example](MISSING.md)
      ```
      ---
    MARKDOWN

    assert_empty MarkdownLinkContract.links(markdown)
    assert_empty MarkdownLinkContract.heading_anchors(markdown)
  end

  def test_ignores_links_inside_matched_inline_code_spans
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        `[Inline example](MISSING-ONE.md)`
        ``[Example with `backtick`](MISSING-TWO.md)``
        [Guide](GUIDE.md)
        [Visible missing](VISIBLE-MISSING.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "VISIBLE-MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)
    end
  end

  def test_unmatched_and_different_length_backticks_do_not_hide_links
    with_docs do |root, source, _target|
      source.write("`[Unmatched](MISSING-ONE.md)\n")
      assert_equal ['references missing or unsafe local target "MISSING-ONE.md"'],
                   MarkdownLinkContract.validate(source, root)

      source.write("``[Wrong closer](MISSING-TWO.md)`\n")
      assert_equal ['references missing or unsafe local target "MISSING-TWO.md"'],
                   MarkdownLinkContract.validate(source, root)

      source.write("` unmatched\n``[Hidden later span](MISSING-THREE.md)``\n")
      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_escaped_opening_backtick_does_not_hide_rendered_link
    with_docs do |root, source, _target|
      source.write("\\`[Visible](MISSING.md)`\n")

      assert_equal ['references missing or unsafe local target "MISSING.md"'],
                   MarkdownLinkContract.validate(source, root)

      source.write("\\\\`[Hidden](MISSING.md)`\n")
      assert_empty MarkdownLinkContract.validate(source, root)
    end
  end

  def test_ignores_links_and_headings_inside_html_comments
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        # Visible

        <!-- [Missing](MISSING.md) -->
        <!--
        ## Hidden Heading
        Hidden Setext Heading
        ---------------------
        ![Missing image](missing.png)
        -->

        [Guide](GUIDE.md)
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
      assert_equal ['visible'], MarkdownLinkContract.heading_anchors(source.read)
    end
  end

  def test_preserves_rendered_structure_around_html_comments
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        # Before
        <!-- hidden -->
        ## After

        Not a heading
        <!-- preserves the rendered line boundary -->
        -------------

        [Guide](GUIDE.md) <!-- [Missing](MISSING.md) --> [Setup](GUIDE.md#setup--usage)
        [Not a link]<!-- boundary -->(MISSING.md)
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
      assert_equal %w[before after], MarkdownLinkContract.heading_anchors(source.read)
      assert_equal %w[GUIDE.md GUIDE.md#setup--usage],
                   MarkdownLinkContract.links(source.read).map { |link| [link[:path], link[:fragment]].compact.join('#') }
    end
  end

  def test_bang_closed_html_comments_resume_rendered_markdown
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        <!--
        # Hidden
        [Hidden](MISSING-HIDDEN.md)
        --!>
        # Visible
        [Visible](MISSING-VISIBLE.md)
      MARKDOWN

      assert_equal ['references missing or unsafe local target "MISSING-VISIBLE.md"'],
                   MarkdownLinkContract.validate(source, root)
      assert_equal ['visible'], MarkdownLinkContract.heading_anchors(source.read)
    end
  end

  def test_unclosed_html_comment_hides_remaining_structure
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        # Visible

        <!-- [Missing](MISSING.md)
        ## Hidden Heading

        ```text
        -->
        ```

        [Still hidden](STILL-MISSING.md)
        ## Still Hidden Heading
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
      assert_equal ['visible'], MarkdownLinkContract.heading_anchors(source.read)
    end
  end

  def test_comment_delimiters_inside_code_do_not_hide_rendered_markdown
    with_docs do |root, source, _target|
      source.write(<<~MARKDOWN)
        `<!--` [Missing inline](MISSING-INLINE.md)

        ```text
        <!--
        ```

        [Missing after fence](MISSING-FENCE.md)
        # Visible Heading
      MARKDOWN

      failures = MarkdownLinkContract.validate(source, root)
      assert_equal 2, failures.length
      assert failures.any? { |failure| failure.include?('MISSING-INLINE.md') }
      assert failures.any? { |failure| failure.include?('MISSING-FENCE.md') }
      assert_equal ['visible-heading'], MarkdownLinkContract.heading_anchors(source.read)
    end
  end

  def test_rejects_fragments_that_only_match_fenced_code
    with_docs do |root, source, target|
      target.write("```text\n# Not A Heading\n```\n# Real Heading\n")
      source.write("[Code heading](GUIDE.md#not-a-heading)\n[Real](GUIDE.md#real-heading)\n")

      failures = MarkdownLinkContract.validate(source, root)
      assert_includes failures, 'references missing Markdown anchor "not-a-heading" in "GUIDE.md"'
      refute failures.any? { |failure| failure.include?('real-heading') }
    end
  end

  def test_accepts_setext_heading_anchors_and_mixed_duplicate_suffixes
    with_docs do |root, source, target|
      target.write(<<~MARKDOWN)
        Guide Title
        ===========

        ## Repeat

        Repeat
        ------

        Repeat
        ======
      MARKDOWN
      source.write(<<~MARKDOWN)
        Home Title
        ==========

        [Home](#home-title)
        [Guide](GUIDE.md#guide-title)
        [Second repeat](GUIDE.md#repeat-1)
        [Third repeat](GUIDE.md#repeat-2)
      MARKDOWN

      assert_empty MarkdownLinkContract.validate(source, root)
      assert_equal %w[guide-title repeat repeat-1 repeat-2],
                   MarkdownLinkContract.heading_anchors(target.read)
    end
  end

  def test_ignores_setext_lookalikes_inside_fences_and_after_blank_lines
    markdown = <<~MARKDOWN
      ```text
      Hidden Setext
      =============
      ```

      Visible Setext
      --------------

      ---

      - List Item
      ---

      \tIndented code
      ---

      Final Heading
      =============
    MARKDOWN

    assert_equal %w[visible-setext final-heading],
                 MarkdownLinkContract.heading_anchors(markdown)
  end

  def test_repository_checker_and_makefile_run_the_contract
    checker = File.read(File.expand_path('check-roadmap-docs.rb', __dir__))
    makefile = File.read(File.expand_path('../Makefile', __dir__))

    assert_equal 2, checker.scan('MarkdownLinkContract.validate(source, ROOT)').length
    assert_includes checker, 'Makefile must run #{test_path}'
    assert_includes makefile, 'scripts/test-markdown-link-contract.rb'
  end
end
