# frozen_string_literal: true

module Overphishing
  class MailParser
    def initialize
      @line_end = "\n"
    end

    def parse(contents)
      headers, body = separate(contents)
      Mail.new(
        original_email: contents,
        original_headers: headers,
        original_body: body,
        headers: extract_headers(headers)
      )
    end

    private

    def separate(contents)
      contents.split("#{@line_end}#{@line_end}")
    end

    def extract_headers(headers)
      parse_headers(unfold_headers(headers).split(@line_end))
    end

    def unfold_headers(headers)
      headers.gsub(/#{@line_end}[\s\t]+/, ' ')
    end

    def parse_headers(headers_array)
      headers_array.inject({}) do |memo, header_string|
        header, value = header_string.split(":", 2)
        memo.merge(convert_header_name(header) => convert_header_value(value)) do |_, existing, new|
          if existing.is_a? Array
            existing << new
          else
            [existing, new]
          end
        end
      end
    end

    def convert_header_name(header)
      header.gsub(/-/, '_').downcase.to_sym
    end

    def convert_header_value(value)
      value.strip
    end
  end
end
