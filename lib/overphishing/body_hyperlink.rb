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

    def supports_retrieval?
      @type == :url && href.is_a?(URI)
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
      stripped_href = href.strip

      (@type == :url && !stripped_href.empty?) ? URI.parse(strip_off_fragments(stripped_href)) : stripped_href
    end

    def strip_off_fragments(uri)
      uri.split('#').first
    end
  end
end
