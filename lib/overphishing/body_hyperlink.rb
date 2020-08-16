# frozen_string_literal: true

module Overphishing
  class BodyHyperlink
    attr_reader :href, :text

    def initialize(href, text)
      @href = URI.parse(sanitize_uri(href))
      @text = text
    end

    def ==(other)
      href == other.href && text == other.text
    end

    private

    def sanitize_uri(uri)
      uri.gsub(/##.+\z/, '')
    end
  end
end
