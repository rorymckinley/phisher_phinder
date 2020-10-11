# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module ReceivedHeaders
      class ByParser
        def initialize(extended_ip_factory)
          @extended_ip_factory = extended_ip_factory
        end

        def parse(component)
          unless component
            return {
              recipient: nil,
              protocol: nil,
              id: nil,
              recipient_additional: nil,
              authenticated_as: nil
            }
          end

          patterns = [
            %r{by\s(?<recipient>\S+)\s
             \((?<additional>[^)]+)\)\s
             with\sMicrosoft\sSMTP\sServer\s\([^\)]+\)\s
             id\s(?<id>\S+)\s
             via\s(?<protocol>Frontend\sTransport)
            }x,
            /by\s(?<recipient>\S+)\swith\s(?<protocol>\S+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\swith\s(?<protocol>\S+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s(?<additional>.+)\swith\s(?<protocol>\S+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\swith\s(?<protocol>.+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\swith\s(?<protocol>\S+)\sID\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\swith\s(?<protocol>.+)\sid\s(?<id>\S+)/,
            /by\s(?<recipient>\S+)\swith\s(?<protocol>.+)/,
            /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\s\(authenticated as (?<authenticated_as>[^\)]+)\)\sid\s(?<id>\S+)/,
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || component.match(pattern)
          end

          {
            recipient: enrich_recipient(matches[:recipient]),
            protocol: matches.names.include?('protocol') ? matches[:protocol]: nil,
            id: matches.names.include?('id') ? matches[:id]: nil,
            recipient_additional: matches.names.include?('additional') ? matches[:additional] : nil,
            authenticated_as: matches.names.include?('authenticated_as') ? matches[:authenticated_as] : nil,
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
