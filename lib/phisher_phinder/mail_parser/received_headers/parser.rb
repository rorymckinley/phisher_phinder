# frozen_string_literal: true

module PhisherPhinder
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
          elsif scanner.check(/from\s.+?\(HELO\s[^)]+\)\s\([^\)]*?\)/)
            from_part = scanner.scan(/from.+?(?=by)/)
          elsif scanner.check(/from\s[^)(]+\sby/)
            from_part = scanner.scan(/from.+?(?=by)/)
          else
            from_part = scanner.scan(/from\s.+?\([^)]+?\)/)
          end

          if scanner.check(/.+\S+\s+by/)
            starttls_part = scanner.scan(/.+\s(?=by)/)
            by_part = scanner.scan(/\s?by.+?\sid\s[\S]+\s?/)
            for_part = scanner.scan(/for\s+\S+/)
          elsif scanner.check(/\s?by.*with Microsoft SMTP Server.*id.*via Frontend Transport/)
            by_part = scanner.scan(/\sby.*Frontend Transport/)
            starttls_part = by_part
          elsif scanner.check(/\s?by.+?\s(id|ID)\s[\S]+\s?/)
            by_part = scanner.scan(/\s?by.+?\s(id|ID)\s[\S]+\s?/) unless scanner.eos?
            for_part = scanner.scan(/for\s+\S+/) unless scanner.eos?
            starttls_part = scanner.rest unless scanner.eos?
          elsif scanner.check(/by.+(?!\sid)/)
            by_part = scanner.scan(/.+/)
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
