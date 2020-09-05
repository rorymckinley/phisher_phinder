# frozen_string_literal: true

module Overphishing
  class BodyHyperlink
    attr_reader :href, :text, :type

    def initialize(href, text)
      @type = classify_href(href.strip)
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
      @type == :url ? URI.parse(sanitize_uri(href.strip)) : href.strip
    end

    def sanitize_uri(uri)
      uri.gsub(/##.+\z/, '')
    end
  end
end
