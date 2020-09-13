# frozen_string_literal: true

module Overphishing
  class BodyHyperlink
    attr_reader :href, :text, :type, :raw_href

    def initialize(href, text)
      @type = classify_href(href.strip)
      @raw_href = href
      @href = parse_href(href)
      @text = text
    end

    def ==(other)
      href == other.href && text == other.text
    end

    private

    def classify_href(href_value)
      case href_value
      when /\A#/
        :url_fragment
      when /\Amailto:/
        :email_address
      when /\Atel:/
        :telephone_number
      else
        :url
      end
    end

    def parse_href(href)
      @type == :url ? URI.parse(strip_off_fragments(href.strip)) : href.strip
    end

    def strip_off_fragments(uri)
      uri.split('#').first
    end
  end
end
