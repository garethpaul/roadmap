#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'overview-svg-contract'

class OverviewSvgContractTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  VALID_SVG = File.read(File.join(ROOT, 'docs/readme-overview.svg'))

  def test_accepts_checked_in_overview
    assert_empty OverviewSvgContract.validate(VALID_SVG)
  end

  def test_rejects_malformed_xml
    assert_failure(VALID_SVG.sub('</svg>', ''), /valid XML/)
    assert_failure(VALID_SVG.sub('<svg ', "<!DOCTYPE svg>\n<svg "), /doctype/)
    stylesheet = VALID_SVG.sub('<svg ', "<?xml-stylesheet href=\"https://example.com/a.css\"?>\n<svg ")
    assert_failure(stylesheet, /processing instructions/)
  end

  def test_rejects_wrong_root_or_namespace
    wrong_root = VALID_SVG.sub('<svg ', '<g ').sub('</svg>', '</g>')
    assert_failure(wrong_root, /canonical SVG namespace/)
    assert_failure(VALID_SVG.sub(' xmlns="http://www.w3.org/2000/svg"', ''), /canonical SVG namespace/)
  end

  def test_rejects_broken_accessible_name_relationship
    assert_failure(VALID_SVG.sub('aria-labelledby="title desc"', 'aria-labelledby="title"'), /aria-labelledby/)
    assert_failure(VALID_SVG.sub('<title id="title">', '<title>'), /title#title/)
    assert_failure(VALID_SVG.sub('<desc id="desc">', '<desc>'), /desc#desc/)
  end

  def test_rejects_active_or_foreign_elements
    %w[script style foreignObject image use].each do |element|
      assert_failure(inject("<#{element} />"), /must not contain/i)
    end
  end

  def test_rejects_event_handlers_and_linked_resources
    assert_failure(VALID_SVG.sub('<svg ', '<svg onload="alert(1)" '), /event-handler/)
    assert_failure(inject('<a href="https://example.com"><text>link</text></a>'), /linked-resource/)
    xlink = VALID_SVG.sub('<svg ', '<svg xmlns:xlink="http://www.w3.org/1999/xlink" ')
    assert_failure(xlink.sub('</svg>', '<a xlink:href="https://example.com" />\n</svg>'), /linked-resource/)
    assert_failure(inject('<rect style="fill: url(https://example.com/a.svg)" />'), /CSS url/)
  end

  def test_wires_svg_contract_into_repository_gates
    checker = File.read(File.join(ROOT, 'scripts/check-roadmap-docs.rb'))
    makefile = File.read(File.join(ROOT, 'Makefile'))

    assert_includes checker, 'OverviewSvgContract.validate'
    assert_includes makefile, 'scripts/test-overview-svg-contract.rb'
  end

  private

  def inject(fragment)
    VALID_SVG.sub('</svg>', "#{fragment}\n</svg>")
  end

  def assert_failure(source, pattern)
    failures = OverviewSvgContract.validate(source)
    refute_empty failures
    assert failures.any? { |failure| failure.match?(pattern) }, failures.inspect
  end
end
