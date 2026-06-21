#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'open3'
require 'yaml'
require_relative 'markdown-link-contract'
require_relative 'overview-svg-contract'

ROOT = Pathname.new(__dir__).parent.expand_path
DOCS_PLANS = ROOT.join('docs/plans')
CANONICAL_PLAN = DOCS_PLANS.join('2026-06-08-roadmap-baseline.md')
SCOPE_CHECKLIST_PLAN = DOCS_PLANS.join('2026-06-09-scope-prerequisite-checklist-guard.md')
HOSTED_VALIDATION_PLAN = DOCS_PLANS.join('2026-06-10-hosted-document-validation.md')
MARKDOWN_ANCHOR_PLAN = DOCS_PLANS.join('2026-06-13-markdown-anchor-integrity.md')
MAKE_ROOT_PLAN = DOCS_PLANS.join('2026-06-14-make-root-override-protection.md')
SAFE_MAKE_AUTHORITY_PLAN = DOCS_PLANS.join('2026-06-21-safe-make-authority.md')
FENCED_HEADING_PLAN = DOCS_PLANS.join('2026-06-14-fenced-heading-anchor-integrity.md')
SETEXT_HEADING_PLAN = DOCS_PLANS.join('2026-06-14-setext-heading-anchor-validation.md')
FENCED_LINK_PLAN = DOCS_PLANS.join('2026-06-17-fenced-link-exclusion.md')
HTML_COMMENT_PLAN = DOCS_PLANS.join('2026-06-17-html-comment-exclusion.md')
HOSTED_VALIDATION_WORKFLOW = ROOT.join('.github/workflows/check.yml')
MAKEFILE = ROOT.join('Makefile')
EXPECTED_HOSTED_VALIDATION_WORKFLOW = <<~YAML
  name: Check

  on:
    push:
    pull_request:
    workflow_dispatch:

  permissions:
    contents: read

  concurrency:
    group: check-${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true

  jobs:
    documentation:
      name: Ruby ${{ matrix.ruby-version }} documentation
      runs-on: ubuntu-24.04
      timeout-minutes: 5
      strategy:
        fail-fast: false
        matrix:
          ruby-version: ["2.7", "3.3"]
      steps:
        - name: Check out repository
          uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3
          with:
            persist-credentials: false

        - name: Set up Ruby
          uses: ruby/setup-ruby@89f90524b88a01fe6e0b732220432cc6142926af # v1.313.0
          with:
            ruby-version: ${{ matrix.ruby-version }}

        - name: Validate roadmap documents
          run: make check
YAML
EXPECTED_ISSUE_TEMPLATE_CONFIG = {
  'blank_issues_enabled' => false,
  'contact_links' => [
    {
      'name' => 'Security Policy',
      'url' => 'https://github.com/garethpaul/roadmap/security/policy',
      'about' => 'Review private vulnerability reporting guidance before sharing sensitive details.'
    },
    {
      'name' => 'Repository Scope',
      'url' => 'https://github.com/garethpaul/roadmap/blob/main/SCOPE.md',
      'about' => 'Read the current README and vision before proposing roadmap scope.'
    }
  ]
}.freeze
failures = []

def rel(path)
  Pathname.new(path).relative_path_from(ROOT).to_s
end

def read(path)
  ROOT.join(path).read
end

if CANONICAL_PLAN.file?
  # The canonical plan records the current documentation-only baseline.
else
  failures << "#{rel(CANONICAL_PLAN)} is missing"
end
failures << "#{rel(SCOPE_CHECKLIST_PLAN)} is missing" unless SCOPE_CHECKLIST_PLAN.file?
failures << "#{rel(HOSTED_VALIDATION_PLAN)} is missing" unless HOSTED_VALIDATION_PLAN.file?

if MARKDOWN_ANCHOR_PLAN.file?
  markdown_anchor_plan = MARKDOWN_ANCHOR_PLAN.read
  [
    'passed 6 tests and 23 assertions',
    'outside-directory `make check` passed',
    'rejected all twelve hostile mutations',
    'read-only Ruby 2.7.8 and Ruby 3.3.11 containers passed',
    'focused contract and syntax checks'
  ].each do |evidence|
    unless markdown_anchor_plan.include?(evidence)
      failures << "#{rel(MARKDOWN_ANCHOR_PLAN)} must record verification evidence #{evidence.inspect}"
    end
  end
else
  failures << "#{rel(MARKDOWN_ANCHOR_PLAN)} is missing"
end

if MAKEFILE.file?
  makefile = MAKEFILE.read
  [
    'override SHELL := /bin/sh',
    'override .SHELLFLAGS := -c',
    'override RUBY := ruby',
    'ifneq ($(strip $(MAKEFILES)),)',
    '$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)',
    'ifneq ($(origin MAKEFILE_LIST),file)',
    '$(error MAKEFILE_LIST must not be overridden)',
    'override ROOT := $(shell path=',
    '[ -f "$$path" ] || exit 1',
    'export ROOT',
    '$(error repository Makefile path could not be resolved)',
    '"$$ROOT/scripts/test-makefile-root.sh"'
  ].each do |fragment|
    failures << "Makefile must preserve authority contract #{fragment.inspect}" unless makefile.include?(fragment)
  end
  %w[
    scripts/test-markdown-link-contract.rb
    scripts/test-overview-svg-contract.rb
  ].each do |test_path|
    failures << "Makefile must run #{test_path}" unless makefile.include?(test_path)
  end
else
  failures << 'Makefile is missing'
end

make_root_test = ROOT.join('scripts/test-makefile-root.sh')
if make_root_test.file?
  root_test = make_root_test.read
  ['54 executed target/authority cases', '2 MAKEFILE_LIST rejections', '1 MAKEFILES rejection', '1 multi-Makefile rejection'].each do |fragment|
    failures << "Makefile root test must preserve #{fragment.inspect}" unless root_test.include?(fragment)
  end
else
  failures << 'scripts/test-makefile-root.sh is missing'
end

if MAKE_ROOT_PLAN.file?
  make_root_plan = MAKE_ROOT_PLAN.read
  [
    'Status: Completed',
    '`make ROOT=/tmp check` passed',
    'all five public Make aliases passed',
    'Six hostile mutations were rejected',
    'Ruby 2.7.8 and Ruby 3.3.11'
  ].each do |evidence|
    unless make_root_plan.include?(evidence)
      failures << "#{rel(MAKE_ROOT_PLAN)} must record verification evidence #{evidence.inspect}"
    end
  end
else
  failures << "#{rel(MAKE_ROOT_PLAN)} is missing"
end

if SAFE_MAKE_AUTHORITY_PLAN.file?
  safe_make_authority_plan = SAFE_MAKE_AUTHORITY_PLAN.read
  [
    '54 executed target, root, shell, and Ruby authority cases',
    'Both `MAKEFILE_LIST` override channels',
    '`MAKEFILES` preload',
    'ambiguous multiple-Makefile invocation failed closed'
  ].each do |evidence|
    failures << "#{rel(SAFE_MAKE_AUTHORITY_PLAN)} must record verification evidence #{evidence.inspect}" unless safe_make_authority_plan.include?(evidence)
  end
else
  failures << "#{rel(SAFE_MAKE_AUTHORITY_PLAN)} is missing"
end

if FENCED_HEADING_PLAN.file?
  fenced_heading_plan = FENCED_HEADING_PLAN.read
  [
    'Status: Completed',
    'repository-root and external-directory `make check` passed',
    'Ten tests and 29 assertions passed',
    'hostile fence mutations were rejected'
  ].each do |evidence|
    unless fenced_heading_plan.include?(evidence)
      failures << "#{rel(FENCED_HEADING_PLAN)} must record verification evidence #{evidence.inspect}"
    end
  end
else
  failures << "#{rel(FENCED_HEADING_PLAN)} is missing"
end

if SETEXT_HEADING_PLAN.file?
  setext_heading_plan = SETEXT_HEADING_PLAN.read
  [
    'Status: Completed',
    'repository-root and external-directory `make check` passed',
    'Twelve tests and 33 assertions passed',
    'hostile Setext mutations were rejected'
  ].each do |evidence|
    unless setext_heading_plan.include?(evidence)
      failures << "#{rel(SETEXT_HEADING_PLAN)} must record verification evidence #{evidence.inspect}"
    end
  end
else
  failures << "#{rel(SETEXT_HEADING_PLAN)} is missing"
end

if FENCED_LINK_PLAN.file?
  fenced_link_plan = FENCED_LINK_PLAN.read
  [
    'Status: Completed',
    'repository-root and external-directory `make check` passed',
    'Nineteen tests and 48 assertions passed',
    'hostile fenced-link mutations were rejected',
    'Exact diff'
  ].each do |evidence|
    unless fenced_link_plan.include?(evidence)
      failures << "#{rel(FENCED_LINK_PLAN)} must record verification evidence #{evidence.inspect}"
    end
  end
else
  failures << "#{rel(FENCED_LINK_PLAN)} is missing"
end

if HTML_COMMENT_PLAN.file?
  html_comment_plan = HTML_COMMENT_PLAN.read
  [
    'Status: Completed',
    'repository and external-directory `make check` passed',
    'Twenty-three tests and 62 assertions passed',
    'hostile HTML-comment mutations were rejected',
    'Exact diff'
  ].each do |evidence|
    unless html_comment_plan.include?(evidence)
      failures << "#{rel(HTML_COMMENT_PLAN)} must record verification evidence #{evidence.inspect}"
    end
  end
else
  failures << "#{rel(HTML_COMMENT_PLAN)} is missing"
end

if HOSTED_VALIDATION_WORKFLOW.file?
  workflow = HOSTED_VALIDATION_WORKFLOW.read
  unless workflow == EXPECTED_HOSTED_VALIDATION_WORKFLOW
    failures << "#{rel(HOSTED_VALIDATION_WORKFLOW)} must match the reviewed credential-free contract"
  end
else
  failures << "#{rel(HOSTED_VALIDATION_WORKFLOW)} is missing"
end

docs_plans = Dir.glob(DOCS_PLANS.join('*.md')).sort
if docs_plans.empty?
  failures << 'docs/plans must contain at least one completed plan'
end

docs_plans.each do |plan_path|
  plan = File.read(plan_path)
  status_lines = plan.lines.map(&:chomp).select { |line| line.match?(/\A(?:## )?Status:/) }
  completed_statuses = status_lines.select { |line| ['Status: Completed', '## Status: Completed'].include?(line) }
  unless status_lines.length == 1 && completed_statuses.length == 1 && plan.include?('make check')
    failures << "#{rel(plan_path)} must record completed status and make check verification"
  end
end

required_docs = %w[.gitignore AGENTS.md README.md SCOPE.md VISION.md SECURITY.md docs/readme-overview.svg]
required_docs.each do |path|
  failures << "#{path} is missing" unless ROOT.join(path).file?
end

checker_source = Pathname.new(__FILE__).read
[
  ['EXPECTED_ISSUE_TEMPLATE', '_CONFIG = {'].join,
  ['YAML.safe_', 'load(config_path.read)'].join,
  ['config == EXPECTED_ISSUE_TEMPLATE', '_CONFIG'].join,
  "'git', '-C', ROOT.to_s, 'ls-files', '--stage', '-z'",
  'MarkdownLinkContract.validate(source, ROOT)'
].each do |fragment|
  failures << "scripts/check-roadmap-docs.rb must include #{fragment.inspect}" unless checker_source.include?(fragment)
end

markdown_contract_source = read('scripts/markdown-link-contract.rb')
unless markdown_contract_source.include?('fence_marker = nil') &&
       markdown_contract_source.include?('fence_length = nil') &&
       markdown_contract_source.include?('Regexp.escape(fence_marker)') &&
       markdown_contract_source.include?("opening_fence[1].start_with?('~')")
  failures << 'scripts/markdown-link-contract.rb must ignore headings inside matching fenced code blocks'
end
unless markdown_contract_source.include?('setext_candidate = nil') &&
       markdown_contract_source.include?('setext_underline = content.match') &&
       markdown_contract_source.include?('append_heading_anchor(anchors, used, setext_candidate)') &&
       markdown_contract_source.include?('def setext_heading_candidate(content)')
  failures << 'scripts/markdown-link-contract.rb must validate simple Setext heading anchors'
end
unless markdown_contract_source.include?('def parse_angle_destination(contents, index)') &&
       markdown_contract_source.include?('def parse_bare_destination(contents, index, stop_at_space:, allow_end: false)') &&
       markdown_contract_source.include?('def parse_parenthesized_destination(contents, index)')
  failures << 'scripts/markdown-link-contract.rb must validate angle-wrapped destinations with literal spaces'
end
unless markdown_contract_source.include?('def fence_aware_lines(contents)') &&
       markdown_contract_source.include?('def markdown_segments(contents)') &&
       markdown_contract_source.include?('markdown_segments(contents).flat_map') &&
       markdown_contract_source.include?("fence_aware_lines(contents).map { |line| line || '' }.join(\"\\n\")") &&
       markdown_contract_source.include?('projection.empty? ? [] : [projection]') &&
       markdown_contract_source.include?('yield nil') &&
       markdown_contract_source.include?('def mask_inline_code_spans(contents)') &&
       markdown_contract_source.include?('matching_backtick_run(') &&
       markdown_contract_source.include?('search_from = opening_index + opening_length') &&
       markdown_contract_source.include?('backslashes.odd?') &&
       markdown_contract_source.include?('block_content = raw_html_line_content(content, block_start)')
  failures << 'scripts/markdown-link-contract.rb must exclude links inside code examples'
end
unless markdown_contract_source.include?('def mask_html_comments(contents)') &&
       markdown_contract_source.include?("contents.index('<!--', cursor)") &&
       markdown_contract_source.include?('def html_comment_end(contents, start_index)') &&
       markdown_contract_source.include?("contents.index('--!>', start_index)") &&
       markdown_contract_source.include?('mask_preserving_newlines') &&
       markdown_contract_source.include?('next_matched_code_span') &&
       markdown_contract_source.include?('markdown_segments(contents)')
  failures << 'scripts/markdown-link-contract.rb must exclude HTML comments without joining rendered Markdown'
end
unless markdown_contract_source.include?('COMMONMARK_HTML_BLOCK_TAGS') &&
       markdown_contract_source.include?('def raw_html_block_start(content, block_start)') &&
       markdown_contract_source.include?('def complete_open_or_closing_tag_line?(line)') &&
       markdown_contract_source.include?('def raw_html_line_content(content, block_start = true)') &&
       markdown_contract_source.include?('def container_marker_can_interrupt_paragraph?(marker, block_start)') &&
       markdown_contract_source.include?('block_start && complete_open_or_closing_tag_line?') &&
       markdown_contract_source.include?('raw_html_until_blank')
  failures << 'scripts/markdown-link-contract.rb must exclude CommonMark raw HTML blocks'
end
unless markdown_contract_source.include?('current_block_start = block_start') &&
       markdown_contract_source.include?('def indented_code_line?(content)') &&
       markdown_contract_source.include?('indented_code = false')
  failures << 'scripts/markdown-link-contract.rb must allow reference definitions after indented code blocks'
end
unless markdown_contract_source.include?('target = CGI.unescapeHTML(target)')
  failures << 'scripts/markdown-link-contract.rb must decode destination character references'
end

markdown_test_source = read('scripts/test-markdown-link-contract.rb')
%w[
  test_ignores_atx_headings_inside_backtick_and_tilde_fences
  test_requires_matching_fence_marker_and_minimum_closing_length
  test_requires_three_markers_and_valid_backtick_info
  test_rejects_fragments_that_only_match_fenced_code
  test_accepts_setext_heading_anchors_and_mixed_duplicate_suffixes
  test_ignores_setext_lookalikes_inside_fences_and_after_blank_lines
  test_validates_literal_spaces_in_angle_destinations
  test_ignores_inline_links_and_images_inside_matching_fences
  test_requires_matching_marker_and_closing_length_before_links_resume
  test_fenced_link_boundaries_do_not_join_surrounding_markdown
  test_ignores_links_inside_matched_inline_code_spans
  test_unmatched_and_different_length_backticks_do_not_hide_links
  test_escaped_opening_backtick_does_not_hide_rendered_link
  test_ignores_links_and_headings_inside_html_comments
  test_preserves_rendered_structure_around_html_comments
  test_bang_closed_html_comments_resume_rendered_markdown
  test_unclosed_html_comment_hides_remaining_structure
  test_comment_delimiters_inside_code_do_not_hide_rendered_markdown
  test_rejects_reference_style_local_links
  test_reference_definitions_keep_the_first_label
  test_ignores_reference_definitions_with_invalid_trailing_text
  test_validates_multiline_reference_destinations
  test_validates_unindented_multiline_reference_destinations
  test_validates_reference_definitions_after_indented_code_blocks
  test_ignores_reference_definitions_after_indented_paragraph_continuations
  test_ignores_reference_definitions_inside_paragraphs
  test_validates_reference_definitions_after_completed_blocks
  test_ignores_reference_definitions_after_inline_code_paragraphs
  test_ignores_invalid_reference_labels
  test_validates_reference_definitions_inside_block_containers
  test_non_one_ordered_reference_definition_does_not_interrupt_paragraphs
  test_one_ordered_reference_definition_can_interrupt_paragraphs
  test_validates_reference_definitions_in_new_container_blocks
  test_ignores_links_and_reference_definitions_inside_raw_html_blocks
  test_ignores_reference_link_uses_inside_commonmark_raw_html_blocks
  test_ignores_reference_definitions_inside_commonmark_raw_html_blocks
  test_ignores_raw_html_blocks_inside_block_containers
  test_type7_html_blocks_do_not_interrupt_paragraphs
  test_ignores_type7_html_blocks_at_block_start
  test_type7_html_blocks_allow_quoted_attribute_punctuation
  test_malformed_type7_html_attributes_do_not_hide_links
  test_non_one_ordered_html_blocks_do_not_interrupt_paragraphs
  test_validates_reference_definitions_with_multiline_titles
  test_unescapes_reference_label_punctuation
  test_decodes_reference_label_entities
  test_decodes_destination_entities
  test_parses_bare_destinations_with_balanced_parentheses
  test_unescapes_backslash_escaped_destination_characters
  test_preserves_backslashes_before_non_escapable_destination_characters
  test_ignores_bare_destinations_with_unescaped_spaces
  test_ignores_inline_links_inside_indented_code_blocks
  test_ignores_headings_inside_indented_code_blocks
  test_ignores_indented_code_inside_block_containers
  test_ignores_fenced_code_inside_block_containers
  test_non_one_ordered_fences_do_not_interrupt_paragraphs
  test_validates_inline_links_inside_indented_paragraph_continuations
  test_validates_inline_link_titles_after_line_breaks
  test_validates_inline_destinations_after_line_breaks
  test_validates_inline_link_titles_with_line_endings
  test_ignores_angle_destinations_without_title_spacing
  test_ignores_angle_destinations_with_unescaped_less_than
  test_ignores_inline_link_titles_with_blank_lines
  test_validates_nested_images_inside_link_text
  test_validates_rendered_links_inside_literal_brackets
  test_ignores_nested_links_inside_link_text
  test_ignores_gfm_footnotes_as_reference_links
  test_masks_reference_title_continuation_lines
  test_rejects_decoded_null_bytes_without_crashing
  test_rejects_invalid_percent_decoded_encoding_without_crashing
  test_rejects_wrong_case_local_paths
  test_rejects_targets_reached_through_symlinked_directories
].each do |test_name|
  failures << "scripts/test-markdown-link-contract.rb must cover #{test_name}" unless markdown_test_source.include?(test_name)
end

setext_guidance = {
  'README.md' => 'ATX and simple Setext heading anchors',
  'SECURITY.md' => 'ATX and simple Setext heading anchors',
  'VISION.md' => 'ATX and simple Setext heading anchors',
  'CHANGES.md' => 'ATX and simple Setext heading anchors'
}
setext_guidance.each do |path, phrase|
  failures << "#{path} must document #{phrase}" unless read(path).include?(phrase)
end

angle_destination_guidance = {
  'README.md' => 'angle-wrapped destinations with literal spaces',
  'SECURITY.md' => 'angle-wrapped destinations with literal spaces',
  'VISION.md' => 'angle-wrapped destinations with literal spaces',
  'CHANGES.md' => 'angle-wrapped destinations with literal spaces'
}
angle_destination_guidance.each do |path, phrase|
  failures << "#{path} must document #{phrase}" unless read(path).include?(phrase)
end

fenced_link_guidance = {
  'README.md' => 'links inside matching fenced code blocks',
  'SECURITY.md' => 'links inside matching fenced code blocks',
  'VISION.md' => 'links inside matching fenced code blocks',
  'CHANGES.md' => 'links inside matching fenced code blocks'
}
fenced_link_guidance.each do |path, phrase|
  failures << "#{path} must document #{phrase}" unless read(path).include?(phrase)
end

inline_code_guidance = {
  'README.md' => 'inline code spans',
  'SECURITY.md' => 'inline code spans',
  'VISION.md' => 'inline code spans',
  'CHANGES.md' => 'inline code spans'
}
inline_code_guidance.each do |path, phrase|
  failures << "#{path} must document #{phrase}" unless read(path).include?(phrase)
end

html_comment_guidance = {
  'README.md' => 'HTML comments are excluded from rendered link and heading validation',
  'SECURITY.md' => 'HTML comments are excluded from rendered link and heading validation',
  'VISION.md' => 'HTML comments are excluded from rendered link and heading validation',
  'CHANGES.md' => 'HTML comments are excluded from rendered link and heading validation'
}
html_comment_guidance.each do |path, phrase|
  failures << "#{path} must document #{phrase}" unless read(path).include?(phrase)
end

hardened_link_guidance = {
  'README.md' => 'reference-style links, balanced parentheses, exact path casing, decoded null bytes, symlinked path components, CommonMark raw HTML blocks, and indented code boundaries',
  'SECURITY.md' => 'reference-style links, balanced parentheses, exact path casing, decoded null bytes, symlinked path components, CommonMark raw HTML blocks, and indented code boundaries',
  'VISION.md' => 'reference-style links, balanced parentheses, exact path casing, decoded null bytes, symlinked path components, CommonMark raw HTML blocks, and indented code boundaries',
  'CHANGES.md' => 'reference-style links, balanced parentheses, exact path casing, decoded null bytes, symlinked path components, CommonMark raw HTML blocks, and indented code boundaries'
}
hardened_link_guidance.each do |path, phrase|
  failures << "#{path} must document #{phrase}" unless read(path).gsub(/\s+/, ' ').include?(phrase)
end

if ROOT.join('AGENTS.md').file?
  agents = read('AGENTS.md')
  ['make check', 'SCOPE.md', 'secrets'].each do |phrase|
    failures << "AGENTS.md must state: #{phrase}" unless agents.include?(phrase)
  end
end

hosted_documentation_contract = {
  'README.md' => ['GitHub Actions', 'Ruby 2.7', 'Ruby 3.3', 'checkout credential persistence disabled'],
  'SECURITY.md' => ['GitHub Actions', 'persisted checkout credentials', 'tracked secret and editor metadata'],
  'VISION.md' => ['Ruby 2.7', 'Ruby 3.3', 'credential-free GitHub Actions validation'],
  'CHANGES.md' => ['Ruby 2.7 and Ruby 3.3', 'persisted checkout credentials']
}
hosted_documentation_contract.each do |path, phrases|
  next unless ROOT.join(path).file?

  contents = read(path).gsub(/\s+/, ' ')
  phrases.each do |phrase|
    failures << "#{path} must document hosted validation: #{phrase}" unless contents.include?(phrase)
  end
end

issue_template_documentation_contract = {
  'README.md' => 'exact issue-template schema and reviewed contact copy',
  'SECURITY.md' => 'exact issue-template schema and reviewed contact copy',
  'VISION.md' => 'exact issue-template schema and reviewed contact copy',
  'CHANGES.md' => 'exact issue-template schema and reviewed contact copy'
}
issue_template_documentation_contract.each do |path, phrase|
  next unless ROOT.join(path).file?

  failures << "#{path} must document #{phrase}" unless read(path).gsub(/\s+/, ' ').include?(phrase)
end

required_ignore_entries = [
  '.env',
  '.env.*',
  '!.env.example',
  '.DS_Store',
  '.idea/',
  '.vscode/',
  '*.iml',
  'vendor/',
  'coverage/'
]
if ROOT.join('.gitignore').file?
  ignore_entries = read('.gitignore').lines.map(&:chomp)
  required_ignore_entries.each do |entry|
    failures << ".gitignore must include #{entry.inspect}" unless ignore_entries.include?(entry)
  end
end

tracked_output, tracked_error, tracked_status = Open3.capture3(
  'git', '-C', ROOT.to_s, 'ls-files',
  '.env', '.env.*', '.idea/**', '.vscode/**', '*.iml'
)
if tracked_status.success?
  tracked_local_metadata = tracked_output.lines.map(&:chomp).reject { |entry| entry.empty? || entry == '.env.example' }
  unless tracked_local_metadata.empty?
    failures << "local secrets or editor metadata must not be tracked: #{tracked_local_metadata.join(', ')}"
  end
else
  failures << "documentation validation must inspect tracked secret and editor metadata paths: #{tracked_error.strip}"
end

index_output, index_error, index_status = Open3.capture3(
  'git', '-C', ROOT.to_s, 'ls-files', '--stage', '-z'
)
tracked_paths = []
if index_status.success?
  index_output.split("\0").reject(&:empty?).each do |entry|
    metadata, path = entry.split("\t", 2)
    mode, _object_id, stage = metadata.to_s.split(' ', 3)
    if path.nil? || mode != '100644' || stage != '0'
      failures << "tracked repository entries must be stage-0 regular blobs: #{entry.inspect}"
      next
    end
    tracked_paths << path
  end
else
  failures << "documentation validation must inspect tracked file modes: #{index_error.strip}"
end

tracked_paths.grep(/\.md\z/).each do |path|
  source = ROOT.join(path)
  MarkdownLinkContract.validate(source, ROOT).each do |failure|
    failures << "#{path} #{failure}"
  end
end

if ROOT.join('README.md').file?
  readme = read('README.md')
  %w[SCOPE.md SECURITY.md VISION.md].each do |doc|
    failures << "README.md must mention #{doc}" unless readme.include?(doc)
  end

  docs_plans.each do |plan_path|
    plan_reference = rel(plan_path)
    failures << "README.md must reference #{plan_reference}" unless readme.include?(plan_reference)
  end

  readme.scan(%r{docs/plans/[-\w.]+\.md}).each do |plan_reference|
    failures << "README.md references missing plan #{plan_reference}" unless ROOT.join(plan_reference).file?
  end

  [
    'No active roadmap commitments are defined',
    'active delivery plan',
    'owner, audience, timeframe, and commitment level',
    '.github/ISSUE_TEMPLATE/config.yml',
    'blank issues disabled'
  ].each do |phrase|
    failures << "README.md must state: #{phrase}" unless readme.include?(phrase)
  end
end

if ROOT.join('SCOPE.md').file?
  scope = read('SCOPE.md')
  required_scope_phrases = [
    'No active roadmap commitments are defined',
    'does not yet identify a product, project, or audience',
    'should not be treated as an active delivery plan',
    'Roadmap type: product roadmap, personal roadmap, project index, or archive',
    'Owner: the person or team accountable for maintaining the roadmap',
    'Audience: the people expected to read or rely on the roadmap',
    'Timeframe: the period covered by any commitments or historical notes',
    'Commitment level: distinguish intent, committed work, and completed work'
  ]
  required_scope_phrases.each do |phrase|
    failures << "SCOPE.md must state: #{phrase}" unless scope.include?(phrase)
  end
end

if ROOT.join('VISION.md').file?
  vision = read('VISION.md')
  normalized_vision = vision.gsub(/\s+/, ' ')
  [
    'No active roadmap commitments are defined',
    'does not yet define a product, project, audience',
    'Do not add roadmap commitments without an owner and timeframe'
  ].each do |phrase|
    failures << "VISION.md must state: #{phrase}" unless normalized_vision.include?(phrase)
  end
end

if ROOT.join('SECURITY.md').file?
  security = read('SECURITY.md').gsub(/\s+/, ' ')
  [
    'No active roadmap commitments are defined',
    'Security reports are not roadmap commitments'
  ].each do |phrase|
    failures << "SECURITY.md must state: #{phrase}" unless security.include?(phrase)
  end
end

if ROOT.join('docs/readme-overview.svg').file?
  overview = read('docs/readme-overview.svg')
  OverviewSvgContract.validate(overview).each do |failure|
    failures << "docs/readme-overview.svg #{failure}"
  end
  [
    'placeholder planning repository',
    'No active roadmap commitments are defined',
    'SCOPE.md required',
    'No active commitments'
  ].each do |phrase|
    failures << "docs/readme-overview.svg must state: #{phrase}" unless overview.include?(phrase)
  end
end

copied_support_patterns = [
  /twilio/i,
  /stackoverflow\.com\/questions\/tagged\/twilio/i,
  /support\.garethpaul\.com/i,
  /docs\.garethpaul\.com/i,
  /feebdack/i
]

%w[README.md docs/readme-overview.svg .github/ISSUE_TEMPLATE/config.yml].each do |path|
  next unless ROOT.join(path).file?

  contents = read(path)
  copied_support_patterns.each do |pattern|
    failures << "#{path} contains copied support reference matching #{pattern.inspect}" if contents.match?(pattern)
  end
end

config_path = ROOT.join('.github/ISSUE_TEMPLATE/config.yml')
if config_path.file?
  begin
    config = YAML.safe_load(config_path.read) || {}
    unless config == EXPECTED_ISSUE_TEMPLATE_CONFIG
      failures << '.github/ISSUE_TEMPLATE/config.yml must match the exact reviewed placeholder schema and contact copy'
    end
  rescue Psych::SyntaxError => e
    failures << ".github/ISSUE_TEMPLATE/config.yml is invalid YAML: #{e.message}"
  end
else
  failures << '.github/ISSUE_TEMPLATE/config.yml is missing'
end

if failures.empty?
  puts 'Roadmap documentation checks passed'
else
  warn "Roadmap documentation checks failed:\n- #{failures.join("\n- ")}"
  exit 1
end
