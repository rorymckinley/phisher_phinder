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
          body: parse_body(original_body, headers),
          authentication_headers: generate_authentication_headers(headers)
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
          memo.merge(convert_header_name(header) => [enrich_header_value(value, sequence)]) do |_, existing, new|
            existing + new
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
          [:received, :x_received].include?(header_name) ? memo + header_value : memo
        end

        {
          received: restore_sequence(received_header_values).map { |v| parse_received_header(v[:data]) }
        }
      end

      def parse_received_header(value)
        starttls_parser = MailParser::ReceivedHeaders::StarttlsParser.new
        parser = MailParser::ReceivedHeaders::Parser.new(
          by_parser: MailParser::ReceivedHeaders::ByParser.new(
            ip_factory: @enriched_ip_factory, starttls_parser: starttls_parser
          ),
          for_parser: MailParser::ReceivedHeaders::ForParser.new(starttls_parser: starttls_parser),
          from_parser: MailParser::ReceivedHeaders::FromParser.new(
            ip_factory: @enriched_ip_factory, starttls_parser: starttls_parser
          ),
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
          content_type: content_type_data(headers),
          content_transfer_encoding: content_transfer_encoding_data(headers),
        )
      end

      def valid_base64_decoded(text)
        if Base64.strict_encode64(Base64.decode64(text)) == text.gsub(/#{@line_end}/, '')
          Base64.decode64(text)
        end
      end

      def content_type_data(headers)
        (headers[:content_type] && headers[:content_type].first[:data]) || nil
      end

      def content_transfer_encoding_data(headers)
        (headers[:content_transfer_encoding] && headers[:content_transfer_encoding].first[:data]) || nil
      end

      def generate_authentication_headers(headers)
        auth_parser = MailParser::AuthenticationHeaders::Parser.new(
          authentication_results_parser: MailParser::AuthenticationHeaders::AuthResultsParser.new(
            ip_factory: @enriched_ip_factory
          )
        )
        auth_parser.parse(headers)
      end
    end
  end
end
