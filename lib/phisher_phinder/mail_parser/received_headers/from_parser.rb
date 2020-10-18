# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module ReceivedHeaders
      class FromParser
        def initialize(ip_factory:, starttls_parser:)
          @extended_ip_factory = ip_factory
          @starttls_parser = starttls_parser
        end

        def parse(component)
          return {advertised_sender: nil, helo: nil, sender: nil}.merge(@starttls_parser.parse(nil)) unless component

          patterns = [
            /from\s(?<advertised_sender>[\S]+)\s\((?<sender_host>\S+?)\.?\s\[(?<sender_ip>[^\]]+)\]\) \((?<starttls>[^\)]+\))/,
            /from\s(?<advertised_sender>[\S]+)\s\(HELO\s(?<helo>[^)]+)\)\s\(\)/,
            /from\s(?<advertised_sender>[\S]+)\s\(HELO\s(?<helo>[^)]+)\)\s\(\[(?<sender_ip>[^\]]+)\]\)/,
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

          output = {
            advertised_sender: matches[:advertised_sender],
            helo: matches.names.include?('helo') ? matches[:helo] : nil,
            sender: {
              host: matches.names.include?('sender_host') ? matches[:sender_host] : nil,
              ip: matches.names.include?('sender_ip') ? @extended_ip_factory.build(matches[:sender_ip]) : nil
            },
          }

          if matches.names.include?('starttls')
            output.merge(@starttls_parser.parse(matches[:starttls]))
          else
            output.merge(@starttls_parser.parse(nil))
          end
        end
      end
    end
  end
end
