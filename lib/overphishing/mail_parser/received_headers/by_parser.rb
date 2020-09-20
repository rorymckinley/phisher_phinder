# frozen_string_literal: true

module Overphishing
  module MailParser
    module ReceivedHeaders
      class ByParser
        def initialize(extended_ip_factory)
          @extended_ip_factory = extended_ip_factory
        end

        def parse(component)
          return {recipient: nil, protocol: nil, id: nil, recipient_additional: nil} unless component

          patterns = [
            /by\s(?<recipient>\S+)\swith\s(?<protocol>\S+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\swith\s(?<protocol>\S+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s(?<additional>.+)\swith\s(?<protocol>\S+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\swith\s(?<protocol>.+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\swith\s(?<protocol>\S+)\sID\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\swith\s(?<protocol>.+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\swith\s(?<protocol>.+)/,
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || component.match(pattern)
          end

          {
            recipient: enrich_recipient(matches[:recipient]),
            protocol: matches.names.include?('protocol') ? matches[:protocol]: nil,
            id: matches.names.include?('id') ? matches[:id]: nil,
            recipient_additional: matches.names.include?('additional') ? matches[:additional] : nil
          }
        end

        private

        def enrich_recipient(recipient)
          @extended_ip_factory.build(recipient) || recipient
        end
      end
    end
  end
end
