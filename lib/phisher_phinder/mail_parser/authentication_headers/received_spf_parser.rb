# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module AuthenticationHeaders
      class ReceivedSpfParser
        def initialize(ip_factory:)
          @ip_factory = ip_factory
        end

        def parse(value)
          patterns = [
            /\A(?<result>\S+)\s\(domain\sof\s(?<mailfrom>\S+)\sdesignates\s(?<ip>\S+)\sas\spermitted\ssender\)/,
            /\A(?<result>\S+)\s\(domain\sof\s(?<mailfrom>\S+)\sdoes\snot\sdesignate\spermitted\ssender\shosts\)/,
            %r{
              \A(?<result>\S+)\s\(mailfrom\)\s
              identity=(?<identity>[^;]+);\s
              client-ip=(?<client_ip>[^;]+);\s
              helo=(?<helo>[^;]+);\s
              envelope-from=(?<envelope_from>[^;]+);\s
              receiver=(?<receiver>[^;]+)
            }x,
            %r{
              \A(?<result>\S+)\s
              \(
                (?<authserv_id>[^:]+):\s
                transitioning\sdomain\sof\s(?<mailfrom>\S+)\s
                .+?
                \s(?<ip>\S+)\sas\spermitted\ssender
              \)\s
              client-ip=(?<client_ip>[^;]+);\s
              envelope-from=(?<envelope_from>[^;]+);\s
              helo=\[?(?<helo>[^;]+?)\]?;
            }x,
            %r{
              \A(?<result>\S+)\s
              \(
                (?<authserv_id>[^:]+):\s
                best\sguess\srecord\sfor\sdomain\sof\s(?<mailfrom>\S+)\s
                .+?
                \s(?<ip>\S+)\sas\spermitted\ssender
              \)\s
              client-ip=(?<client_ip>[^;]+);
            }x,
            %r{
              \A(?<result>\S+)\s
              \(
                (?<authserv_id>[^:]+):\s
                domain\sof\stransitioning\s(?<mailfrom>\S+)\s
                .+?
                \s(?<ip>\S+)\sas\spermitted\ssender
              \)\s
              client-ip=(?<client_ip>[^;]+);
            }x,
            %r{
              \A(?<result>\S+)\s
              \(
                (?<authserv_id>[^:]+):\s
                domain\sof\s(?<mailfrom>\S+)\s
                .+?
                \s(?<ip>\S+)\sas\spermitted\ssender
              \)\s
              receiver=(?<receiver>[^;]+);\s
              client-ip=(?<client_ip>[^;]+);\s
              helo=\[?(?<helo>[^;]+?)\]?;
            }x,
            %r{
              \A(?<result>\S+)\s
              \(
                (?<authserv_id>[^:]+):\s
                domain\sof\s(?<mailfrom>\S+)\s
                .+?
                \s(?<ip>\S+)\sas\spermitted\ssender
              \)\s
              client-ip=(?<client_ip>[^;]+);
            }x,
            %r{
              \A(?<result>\S+)\s
              \(
                (?<authserv_id>[^:]+):\s
                (?<ip>\S+)\sis\sneither\s
                .+?
                domain\sof\s(?<mailfrom>\S+)
              \)\s
              client-ip=(?<client_ip>[^;]+);
            }x
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || value.match(pattern)
          end

          if matches
            {
              result: matches[:result].downcase.to_sym,
              authserv_id: extract(matches, :authserv_id),
              mailfrom: extract(matches, :mailfrom),
              ip: @ip_factory.build(extract(matches, :ip)),
              client_ip: expand_ip(extract(matches, :client_ip)),
              receiver: extract(matches, :receiver),
              helo: expand_ip(extract(matches, :helo)),
              envelope_from: extract(matches, :envelope_from)
            }
          end
        end

        private

        def extract(matches, key)
          matches.names.include?(key.to_s) ? matches[key] : nil
        end

        def expand_ip(ip)
          ip ? (@ip_factory.build(ip) || ip) : nil
        end
      end
    end
  end
end
