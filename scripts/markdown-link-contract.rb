#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'uri'
require 'cgi'

module MarkdownLinkContract
  LINK_PATTERN = /!?\[[^\]]*\]\(([^)\s]+)(?:\s+["'][^"']*["'])?\)/.freeze
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
    contents.scan(LINK_PATTERN).flatten.filter_map do |raw_target|
      target = raw_target.delete_prefix('<').delete_suffix('>')
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

  def heading_anchors(contents)
    used = {}
    contents.lines.filter_map do |line|
      match = line.match(/\A {0,3}\#{1,6}\s+(.+?)\s*\#*\s*\z/)
      next unless match

      base = heading_slug(match[1])
      next if base.empty?

      anchor = base
      suffix = 0
      while used[anchor]
        suffix += 1
        anchor = "#{base}-#{suffix}"
      end
      used[anchor] = true
      anchor
    end
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
