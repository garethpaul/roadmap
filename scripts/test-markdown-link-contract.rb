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
