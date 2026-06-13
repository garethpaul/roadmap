#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rexml/document'

module OverviewSvgContract
  SVG_NAMESPACE = 'http://www.w3.org/2000/svg'
  DISALLOWED_ELEMENTS = %w[foreignobject image script style use].freeze

  module_function

  def validate(source)
    document = REXML::Document.new(source)
    root = document.root
    failures = []

    failures << 'must not contain a doctype declaration' if document.doctype
    if document.children.any? { |child| child.is_a?(REXML::Instruction) }
      failures << 'must not contain processing instructions'
    end
    unless root&.name == 'svg' && root.namespace == SVG_NAMESPACE
      failures << 'must use an svg root in the canonical SVG namespace'
      return failures
    end

    failures.concat(accessibility_failures(root))
    each_element(root) do |element|
      failures << "must not contain #{element.name} elements" if DISALLOWED_ELEMENTS.include?(element.name.downcase)
      element.attributes.each_attribute do |attribute|
        name = attribute.expanded_name.downcase
        failures << "must not contain event-handler attribute #{name}" if name.start_with?('on')
        failures << "must not contain linked-resource attribute #{name}" if %w[href xlink:href].include?(name)
        failures << "must not contain CSS url() references in #{name}" if attribute.value.match?(/url\s*\(/i)
      end
    end

    failures
  rescue REXML::ParseException => error
    ["must be valid XML: #{error.message.lines.first.strip}"]
  end

  def accessibility_failures(root)
    title = root.elements.to_a.find { |element| element.name == 'title' }
    description = root.elements.to_a.find { |element| element.name == 'desc' }
    failures = []
    failures << 'must declare aria-labelledby="title desc"' unless root.attributes['aria-labelledby'] == 'title desc'
    failures << 'must include title#title' unless title&.attributes&.[]('id') == 'title'
    failures << 'must include desc#desc' unless description&.attributes&.[]('id') == 'desc'
    failures
  end

  def each_element(element, &block)
    yield element
    element.elements.each { |child| each_element(child, &block) }
  end
end
