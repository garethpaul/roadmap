#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'yaml'

ROOT = Pathname.new(__dir__).parent.expand_path
DOCS_PLANS = ROOT.join('docs/plans')
CANONICAL_PLAN = DOCS_PLANS.join('2026-06-08-roadmap-baseline.md')
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

docs_plans = Dir.glob(DOCS_PLANS.join('*.md')).sort
if docs_plans.empty?
  failures << 'docs/plans must contain at least one completed plan'
end

docs_plans.each do |plan_path|
  plan = File.read(plan_path)
  unless plan.include?('Status: Completed') && plan.include?('make check')
    failures << "#{rel(plan_path)} must record completed status and make check verification"
  end
end

required_docs = %w[README.md SCOPE.md VISION.md SECURITY.md docs/readme-overview.svg]
required_docs.each do |path|
  failures << "#{path} is missing" unless ROOT.join(path).file?
end

if ROOT.join('README.md').file?
  readme = read('README.md')
  %w[SCOPE.md SECURITY.md VISION.md].each do |doc|
    failures << "README.md must mention #{doc}" unless readme.include?(doc)
  end

  [
    'No active roadmap commitments are defined',
    'active delivery plan',
    'owner, audience, timeframe, and commitment level'
  ].each do |phrase|
    failures << "README.md must state: #{phrase}" unless readme.include?(phrase)
  end
end

if ROOT.join('SCOPE.md').file?
  scope = read('SCOPE.md')
  required_scope_phrases = [
    'No active roadmap commitments are defined',
    'does not yet identify a product, project, or audience',
    'should not be treated as an active delivery plan'
  ]
  required_scope_phrases.each do |phrase|
    failures << "SCOPE.md must state: #{phrase}" unless scope.include?(phrase)
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
    unless config['blank_issues_enabled'] == false
      failures << '.github/ISSUE_TEMPLATE/config.yml must disable blank issues until roadmap scope is defined'
    end

    Array(config['contact_links']).each do |link|
      %w[name url about].each do |field|
        failures << ".github/ISSUE_TEMPLATE/config.yml contact link is missing #{field}" if link[field].to_s.strip.empty?
      end

      url = link['url'].to_s
      unless url.start_with?('https://github.com/garethpaul/roadmap')
        failures << ".github/ISSUE_TEMPLATE/config.yml contact link #{url} must stay scoped to this repository"
      end
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
