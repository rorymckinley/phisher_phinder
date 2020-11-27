# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module ReceivedHeaders
      class Parser
        def initialize(by_parser:, for_parser:, from_parser:, timestamp_parser:, classifier:)
          @parsers = {
            by: by_parser,
            for: for_parser,
            from: from_parser,
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
            memo.merge(parser.parse(components[component_name])) do |key, old_value, new_value|
              if key == :starttls && old_value
                old_value
              else
                new_value
              end
            end
          end

          output.merge(@classifier.classify(output))
        end

        private

        def extract_value_components(header_value)

          values = {
            time: [],
            for: [],
            by: [],
            from: []
          }

          cleaned_value = header_value.gsub(/\A\(([^\)]+)\)/, '\1')

          tokenised_value = cleaned_value.split(" ")
          current_component = nil

          tokenised_value.each do |val|
            current_component = component_start(val, values) || current_component

            values[current_component] << val if current_component
          end

          values.inject({}) do |memo, (component, values)|
            memo.merge(component => (values.any? ? values.join(' ') : nil))
          end
        end

        def for_scan(scanner)
          return nil if scanner.eos?

          scanner.check(/for\s<[^>]+>/) ? scanner.scan(/for\s<[^>]+>/) : scanner.scan(/for\s+\S+/)
        end

        def component_start(token, values)
          markers = {
            'from' => :from,
            'by' => :by,
            'for' => :for
          }

          return nil unless component = markers[token]

          blocking_components = {
            from: [:by, :for],
            by: [:for],
            for: []
          }

          if blocking_components[component].any? { |blocking_comp| values[blocking_comp].any? }
            nil
          else
            component
          end
        end
      end
    end
  end
end
