# frozen_string_literal: true

module Overphishing
  module MailParser
    module ReceivedHeaders
      class Parser
        def initialize(by_parser:, for_parser:, from_parser:, starttls_parser:, timestamp_parser:, classifier:)
          @parsers = {
            by: by_parser,
            for: for_parser,
            from: from_parser,
            starttls: starttls_parser,
            time: timestamp_parser,
          }
          @classifier = classifier
        end

        def parse(header)
          require 'strscan'

          header_value, timestamp = header.split(';')

          parsers = [@by_parser, @for_parser, @from_parser, @starttls_parser, @timestamp_parser]
          components = extract_value_components(header_value).merge(time: timestamp)

          output = @parsers.inject({}) do |memo, (component_name, parser)|
            memo.merge(parser.parse(components[component_name]))
          end

          output.merge(@classifier.classify(output))
        end

        private

        def extract_value_components(header_value)
          require 'strscan'

          scanner = StringScanner.new(header_value)

          output = {}

          if scanner.check(/\(from\s+[^)]+\)/)
            from_part = scanner.scan(/\(from\s+[^)]+\)/)
          elsif scanner.check(/from\s[^)(]+\sby/)
            from_part = scanner.scan(/from.+?(?=by)/)
          else
            from_part = scanner.scan(/from\s.+?\([^)]+?\)/)
          end

          if scanner.check(/.+\S+\s+by/)
            starttls_part = scanner.scan(/.+\s(?=by)/)
            by_part = scanner.scan(/\s?by.+?\sid\s[\S]+\s?/)
            for_part = scanner.scan(/for\s+\S+/)
          else
            by_part = scanner.scan(/\s?by.+?\s(id|ID)\s[\S]+\s?/) unless scanner.eos?
            for_part = scanner.scan(/for\s+\S+/) unless scanner.eos?
            starttls_part = scanner.rest unless scanner.eos?
          end

          {
            by: by_part,
            for: for_part,
            from: from_part,
            starttls: starttls_part
          }
        end
      end
    end
  end
end
