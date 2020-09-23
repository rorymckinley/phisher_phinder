# frozen_string_literal: true

module PhisherPhinder
  class Mail
    attr_reader :original_email, :original_headers, :original_body, :headers, :tracing_headers, :body

    def initialize(
      original_email:, original_headers:, original_body:, headers:, tracing_headers:, body:
    )
      @original_email = original_email
      @original_headers = original_headers
      @original_body = original_body
      @headers = headers
      @tracing_headers = tracing_headers
      @body = body
    end

    def reply_to_addresses
      @headers[:reply_to].map do |value_string|
        value_string.split(",")
      end.flatten.map do |email_address_string|
        extract_email_address(email_address_string)
      end.uniq
    end

    def hypertext_links
      body_as_html.
        xpath('//a').
        select { |el| el.attributes['href'] }.
        map { |el| BodyHyperlink.new(el.attributes['href'].value, el.text) }
    end

    private

    def body_as_html
      require 'nokogiri'

      Nokogiri::HTML(body[:html])
    end

    def extract_email_address(email_address_string)
      if email_address_string.include? '<'
        email_address_string =~ /<([^>]+)>/
        $1
      else
        email_address_string
      end.downcase.strip
    end
  end
end
