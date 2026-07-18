#!/usr/bin/env ruby
# frozen_string_literal: true

# Out-of-band planted-defect control for the documentation contract suites.
#
# scripts/check-roadmap-docs.rb pins the source text of the contract libraries
# and the names of the tests that defend them. Source-text presence proves a
# guard is spelled in the tree; it cannot prove the test that defends the guard
# still asserts anything. A suite whose assertion mechanism has been neutered
# keeps every pinned name, still reports "0 failures", and still exits 0.
#
# This harness closes that gap by observing the suites actually gate. It copies
# the repository to a temporary directory, plants a defect the shipped suites
# are expected to reject, runs the REAL suite against the copy, and fails when
# the suite still passes.
#
# The control is fail-closed by construction. A neutered assertion mechanism
# makes every planted defect survive, so the harness fails rather than passes.
# The clean-tree control below runs first so that a suite which fails for an
# unrelated reason cannot masquerade as universal detection.

require 'fileutils'
require 'open3'
require 'pathname'
require 'rbconfig'
require 'tmpdir'

ROOT = Pathname.new(__dir__).parent.expand_path
RUBY_BINARY = RbConfig.ruby

MARKDOWN_SUITE = 'scripts/test-markdown-link-contract.rb'
OVERVIEW_SUITE = 'scripts/test-overview-svg-contract.rb'

# Minimum observed work per suite. A neutered assertion mechanism collapses the
# reported assertion count, so these floors reject a suite that runs without
# asserting anything even before a defect is planted.
SUITE_FLOORS = [
  { 'suite' => MARKDOWN_SUITE, 'runs' => 77, 'assertions' => 144 },
  { 'suite' => OVERVIEW_SUITE, 'runs' => 7, 'assertions' => 57 }
].freeze

# Each defect targets a guard that check-roadmap-docs.rb does not pin as source
# text, so the shipped suite is the only control that can reject it.
#
# Two tempting mutations are deliberately absent because they are behaviourally
# equivalent rather than defects, and would fail this harness without indicating
# any real coverage gap:
#
#   * Reducing "target.file? && !target.symlink?" to "target.file?". exact_path?
#     already rejects a symlinked final component, so the second test is
#     redundant defense in depth.
#   * Comparing link path casing case-insensitively. On a case-sensitive
#     filesystem target.file? already rejects a wrong-case target, so that guard
#     only decides on case-insensitive filesystems and hosted Linux validation
#     cannot observe it.
MUTATIONS = [
  {
    'name' => 'symlinked path component accepted',
    'path' => 'scripts/markdown-link-contract.rb',
    'from' => 'return false if current.symlink?',
    'to' => '',
    'suite' => MARKDOWN_SUITE
  },
  {
    'name' => 'decoded null byte accepted',
    'path' => 'scripts/markdown-link-contract.rb',
    'from' => %q(raise ArgumentError, 'decoded value contains null byte' if decoded.include?("\\0")),
    'to' => '',
    'suite' => MARKDOWN_SUITE
  },
  {
    'name' => 'invalid percent escape accepted',
    'path' => 'scripts/markdown-link-contract.rb',
    'from' => "raise ArgumentError, 'invalid percent escape' if value.match?(INVALID_ESCAPE_PATTERN)",
    'to' => '',
    'suite' => MARKDOWN_SUITE
  },
  {
    'name' => 'disallowed SVG elements allowed',
    'path' => 'scripts/overview-svg-contract.rb',
    'from' => "DISALLOWED_ELEMENTS = %w[foreignobject image script style use].freeze",
    'to' => 'DISALLOWED_ELEMENTS = [].freeze',
    'suite' => OVERVIEW_SUITE
  },
  {
    'name' => 'SVG event-handler attributes allowed',
    'path' => 'scripts/overview-svg-contract.rb',
    'from' => %q(failures << "must not contain event-handler attribute #{name}" if name.start_with?('on')),
    'to' => '',
    'suite' => OVERVIEW_SUITE
  }
].freeze

def fail_with(message)
  warn message
  exit 1
end

def prepare_copy(directory)
  copy = File.join(directory, 'checkout')
  FileUtils.mkdir_p(copy)
  Dir.children(ROOT.to_s).each do |entry|
    next if entry == '.git'

    FileUtils.cp_r(File.join(ROOT.to_s, entry), File.join(copy, entry))
  end
  copy
end

def run_suite(copy, suite)
  Open3.capture2e(RUBY_BINARY, suite, chdir: copy)
end

# Applies a mutation to the copy and proves the file actually changed, so a
# stale or mis-typed pattern can never be mistaken for a suite that detected a
# defect that was never planted.
def apply_mutation(copy, mutation)
  path = File.join(copy, mutation['path'])
  before = File.read(path)
  occurrences = before.scan(mutation['from']).length
  unless occurrences == 1
    fail_with(
      "mutation #{mutation['name'].inspect} matched #{occurrences} occurrences of " \
      "#{mutation['from'].inspect} in #{mutation['path']}; expected exactly 1"
    )
  end
  after = before.sub(mutation['from'], mutation['to'])
  fail_with("mutation #{mutation['name'].inspect} did not alter #{mutation['path']}") if after == before

  File.write(path, after)
end

def assert_clean_baseline
  Dir.mktmpdir('roadmap-mutation-control-') do |directory|
    copy = prepare_copy(directory)
    SUITE_FLOORS.each do |floor|
      suite = floor['suite']
      output, status = run_suite(copy, suite)
      unless status.success?
        fail_with("clean-tree control failed: #{suite} did not pass unmutated\n#{output}")
      end

      summary = output.match(/^(\d+) runs, (\d+) assertions, \d+ failures, \d+ errors/)
      fail_with("clean-tree control failed: #{suite} reported no test summary\n#{output}") if summary.nil?

      runs = summary[1].to_i
      assertions = summary[2].to_i
      if runs < floor['runs'] || assertions < floor['assertions']
        fail_with(
          "clean-tree control failed: #{suite} reported #{runs} runs and #{assertions} " \
          "assertions, below the required #{floor['runs']} runs and #{floor['assertions']} " \
          'assertions; the assertion mechanism may be neutered'
        )
      end
    end
  end
end

def assert_mutation_rejected(mutation)
  Dir.mktmpdir('roadmap-mutation-') do |directory|
    copy = prepare_copy(directory)
    apply_mutation(copy, mutation)
    output, status = run_suite(copy, mutation['suite'])
    if status.success?
      fail_with(
        "hostile mutation survived: #{mutation['name']} " \
        "(#{mutation['path']}) was not rejected by #{mutation['suite']}\n#{output}"
      )
    end
  end
end

assert_clean_baseline
MUTATIONS.each { |mutation| assert_mutation_rejected(mutation) }

puts(
  "Contract mutation tests passed: #{SUITE_FLOORS.length} clean-tree suite controls and " \
  "#{MUTATIONS.length} hostile mutations rejected by the shipped suites"
)
