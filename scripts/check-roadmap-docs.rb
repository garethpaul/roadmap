#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'yaml'

ROOT = Pathname.new(__dir__).parent.expand_path
DOCS_PLANS = ROOT.join('docs/plans')
CANONICAL_PLAN = DOCS_PLANS.join('2026-06-08-roadmap-baseline.md')
SCOPE_CHECKLIST_PLAN = DOCS_PLANS.join('2026-06-09-scope-prerequisite-checklist-guard.md')
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
    unless config['blank_issues_enabled'] == false
      failures << '.github/ISSUE_TEMPLATE/config.yml must disable blank issues until roadmap scope is defined'
    end

    contact_links = Array(config['contact_links'])
    if contact_links.empty?
      failures << '.github/ISSUE_TEMPLATE/config.yml must include repository-scoped contact links'
    end

    name_counts = Hash.new(0)
    url_counts = Hash.new(0)
    contact_links.each do |link|
      next unless link.is_a?(Hash)

      name = link['name'].to_s.strip
      url = link['url'].to_s.strip
      name_counts[name] += 1 unless name.empty?
      url_counts[url] += 1 unless url.empty?
    end

    duplicate_names = name_counts.select { |_name, count| count > 1 }.keys.sort
    unless duplicate_names.empty?
      failures << ".github/ISSUE_TEMPLATE/config.yml must not duplicate contact link names: #{duplicate_names.join(', ')}"
    end

    duplicate_urls = url_counts.select { |_url, count| count > 1 }.keys.sort
    unless duplicate_urls.empty?
      failures << ".github/ISSUE_TEMPLATE/config.yml must not duplicate contact link URLs: #{duplicate_urls.join(', ')}"
    end

    expected_contact_links = {
      'Security Policy' => 'https://github.com/garethpaul/roadmap/security/policy',
      'Repository Scope' => 'https://github.com/garethpaul/roadmap/blob/main/SCOPE.md'
    }
    expected_contact_links.each do |name, expected_url|
      matching_link = contact_links.find { |link| link.is_a?(Hash) && link['name'].to_s == name }
      if matching_link.nil?
        failures << ".github/ISSUE_TEMPLATE/config.yml must include the #{name} contact link"
      elsif matching_link['url'].to_s != expected_url
        failures << ".github/ISSUE_TEMPLATE/config.yml #{name} contact link must use #{expected_url}"
      end
    end

    contact_links.each do |link|
      unless link.is_a?(Hash)
        failures << '.github/ISSUE_TEMPLATE/config.yml contact link must be a mapping'
        next
      end

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
