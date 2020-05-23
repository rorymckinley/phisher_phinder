# frozen_string_literal: true

module Overphishing
  class Mail
    attr_reader :original_email, :original_headers, :original_body, :headers
    def initialize(original_email:, original_headers:, original_body:, headers:)
      @original_email = original_email
      @original_headers = original_headers
      @original_body = original_body
      @headers = headers
    end
  end
end
