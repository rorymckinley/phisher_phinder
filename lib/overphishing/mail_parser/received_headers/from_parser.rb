# frozen_string_literal: true

module Overphishing
  module MailParser
    module ReceivedHeaders
      class FromParser
        def initialize(extended_ip_factory)
          @extended_ip_factory = extended_ip_factory
        end

        def parse(component)
          return {advertised_sender: nil, sender: nil} unless component

          patterns = [
            /from\s(?<advertised_sender>[\S]+)\s\((?<sender_host>\S+?)\.?\s\[(?<sender_ip>[^\]]+)\]\)/,
            /from\s(?<advertised_sender>\S+)\s\((?<sender_host>\S+?)\.?\s(?<sender_ip>\S+?)\)/,
            /from\s(?<advertised_sender>\S+)\s\(\[(?<sender_ip>[^\]]+)\]\)/,
            /from\s(?<advertised_sender>\S+)\s\((?<sender_ip>[^)]+)\)/,
            /\(from\s(?<advertised_sender>[^)]+)\)/,
            /from\s(?<advertised_sender>\S+)/,
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || component.match(pattern)
          end

          {
            advertised_sender: matches[:advertised_sender],
            sender: {
              host: matches.names.include?('sender_host') ? matches[:sender_host] : nil,
              ip: matches.names.include?('sender_ip') ? @extended_ip_factory.build(matches[:sender_ip]) : nil
            }
          }
        end
      end
    end
  end
end
