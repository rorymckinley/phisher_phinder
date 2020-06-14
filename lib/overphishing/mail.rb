# frozen_string_literal: true

module Overphishing
  class Mail
    attr_reader :original_email, :original_headers, :original_body, :headers, :tracing_headers

    def initialize(original_email:, original_headers:, original_body:, headers:, tracing_headers: )
      @original_email = original_email
      @original_headers = original_headers
      @original_body = original_body
      @headers = headers
      @tracing_headers = tracing_headers
    end

    def reply_to_addresses
      @headers[:reply_to].map do |value_string|
        value_string.split(",")
      end.flatten.map do |email_address_string|
        extract_email_address(email_address_string)
      end.uniq
    end

    private

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
