# frozen_string_literal: true
require_relative('mail_parser/body_parser')
require_relative('mail_parser/header_value_parser')

module PhisherPhinder
  module MailParser
    class Parser
      def initialize(enriched_ip_factory, line_ending_type)
        @line_end = line_ending_type == 'dos' ? "\r\n" : "\n"
        @enriched_ip_factory = enriched_ip_factory
      end

      def parse(contents)
        original_headers, original_body = separate(contents)
        headers = extract_headers(original_headers)
        Mail.new(
          original_email: contents,
          original_headers: original_headers,
          original_body: original_body,
          headers: headers,
          tracing_headers: generate_tracing_headers(headers),
          body: parse_body(original_body, headers)
        )
      end

      private

      def separate(contents)
        contents.split("#{@line_end}#{@line_end}", 2)
      end

      def extract_headers(headers)
        parse_headers(unfold_headers(headers).split(@line_end))
      end

      def unfold_headers(headers)
        headers.gsub(/#{@line_end}[\s\t]+/, ' ')
      end

      def parse_headers(headers_array)
        headers_array.each_with_index.inject({}) do |memo, (header_string, index)|
          header, value = header_string.split(":", 2)
          sequence = headers_array.length - index - 1
          memo.merge(convert_header_name(header) => enrich_header_value(value, sequence)) do |_, existing, new|
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

      def enrich_header_value(value, sequence)
        {data: HeaderValueParser.new.parse(value), sequence: sequence}
      end

      def generate_tracing_headers(headers)
        received_header_values = headers.inject([]) do |memo, (header_name, header_value)|
          if [:received, :x_received].include? header_name
            if header_value.is_a? Array
              memo +=  header_value
            else
              memo << header_value
            end
          end

          memo
        end.flatten

        {
          received: restore_sequence(received_header_values).map { |v| parse_received_header(v[:data]) }
        }
      end

      def parse_received_header(value)
        parser = MailParser::ReceivedHeaders::Parser.new(
          by_parser: MailParser::ReceivedHeaders::ByParser.new(@enriched_ip_factory),
          for_parser: MailParser::ReceivedHeaders::ForParser.new,
          from_parser: MailParser::ReceivedHeaders::FromParser.new(@enriched_ip_factory),
          starttls_parser: MailParser::ReceivedHeaders::StarttlsParser.new,
          timestamp_parser: MailParser::ReceivedHeaders::TimestampParser.new,
          classifier: MailParser::ReceivedHeaders::Classifier.new
        )
        parser.parse(value)
      end

      def restore_sequence(values)
        values.sort { |a,b| b[:sequence] <=> a[:sequence] }
      end

      def parse_body(original_body, headers)
        MailParser::BodyParser.new(@line_end).parse(
          body_contents: original_body,
          content_type: headers.dig(:content_type, :data),
          content_transfer_encoding: headers.dig(:content_transfer_encoding, :data),
        )
      end

      def valid_base64_decoded(text)
        if Base64.strict_encode64(Base64.decode64(text)) == text.gsub(/#{@line_end}/, '')
          Base64.decode64(text)
        end
      end
    end
  end
end
