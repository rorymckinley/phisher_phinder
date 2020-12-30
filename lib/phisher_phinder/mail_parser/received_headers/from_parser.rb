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
          unless component
            return {
              advertised_authenticated_sender: nil, advertised_sender: nil, helo: nil, sender: nil
            }.merge(@starttls_parser.parse(nil))
          end

          patterns = [
            %r{
              from\s\[(?<advertised_sender>[\S]+)\]\s
              \((?<sender_host>\S+?)\.?\s
              \[(?<sender_ip>[^\]]+)\]\)\s
              \(Authenticated\ssender:\s(?<advertised_authenticated_sender>[^\)]+)\)
            }x,
            /from\s\[(?<sender_ip>[^\]]+)\]\s\(helo=(?<helo>[^\)]+)\)/,
            %r{
              from\s\[(?<advertised_sender>[\S]+)\]\s
              \((?<sender_host>\S+?)\.?\s
              \[(?<sender_ip>[^\]]+)\]\)
            }x,
            /from\s(?<sender_ip>[^\]]+)\s\(EHLO\s(?<helo>[^\)]+)\)/,
            /from\s(?<advertised_sender>[\S]+)\s\((?<sender_host>\S+?)\.?\s\[(?<sender_ip>[^\]]+)\]\) \((?<starttls>[^\)]+\))/,
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
            advertised_sender: expand_advertised_sender(extract(matches, :advertised_sender)),
            helo: matches.names.include?('helo') ? matches[:helo] : nil,
            sender: {
              host: matches.names.include?('sender_host') ? matches[:sender_host] : nil,
              ip: matches.names.include?('sender_ip') ? @extended_ip_factory.build(matches[:sender_ip]) : nil
            },
            advertised_authenticated_sender: matches.names.include?('advertised_authenticated_sender') ? matches[:advertised_authenticated_sender] : nil
          }

          if matches.names.include?('starttls')
            output.merge(@starttls_parser.parse(matches[:starttls]))
          else
            output.merge(@starttls_parser.parse(nil))
          end
        end

        private

        def extract(matches, key)
          matches.names.include?(key.to_s) ? matches[key] : nil
        end

        def expand_advertised_sender(sender)
          sender ? (@extended_ip_factory.build(sender) || sender) : nil
        end
      end
    end
  end
end
