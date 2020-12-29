# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module AuthenticationHeaders
      class ReceivedSpfParser
        def initialize(ip_factory:)
          @ip_factory = ip_factory
        end

        def parse(value)
          matches = value.match(
            %r{
              \A(?<result>\S+)\s
              \((?<additional_data>[^\)]+)\)
              (?<attributes>.*)
            }x
          )

          {
            result: matches[:result].downcase.to_sym,
          }.merge(parse_additional_data(matches[:additional_data])).merge(parse_attributes(matches[:attributes]))

            # {
            #   result: matches[:result].downcase.to_sym,
            #   authserv_id: extract(matches, :authserv_id),
            #   mailfrom: extract(matches, :mailfrom),
            #   ip: @ip_factory.build(extract(matches, :ip)),
            #   client_ip: expand_ip(extract(matches, :client_ip)),
            #   receiver: extract(matches, :receiver),
            #   helo: expand_ip(extract(matches, :helo)),
            #   envelope_from: extract(matches, :envelope_from)
            # }
        end

        # def parse(value)
        #   patterns = [
        #     /\A(?<result>\S+)\s\(domain\sof\s(?<mailfrom>\S+)\sdesignates\s(?<ip>\S+)\sas\spermitted\ssender\)/,
        #     /\A(?<result>\S+)\s\(domain\sof\s(?<mailfrom>\S+)\sdoes\snot\sdesignate\spermitted\ssender\shosts\)/,
        #     %r{
        #       \A(?<result>\S+)\s\(mailfrom\)\s
        #       identity=(?<identity>[^;]+);\s
        #       client-ip=(?<client_ip>[^;]+);\s
        #       helo=(?<helo>[^;]+);\s
        #       envelope-from=(?<envelope_from>[^;]+);\s
        #       receiver=(?<receiver>[^;]+)
        #     }x,
        #     %r{
        #       \A(?<result>\S+)\s
        #       \(
        #         (?<authserv_id>[^:]+):\s
        #         transitioning\sdomain\sof\s(?<mailfrom>\S+)\s
        #         .+?
        #         \s(?<ip>\S+)\sas\spermitted\ssender
        #       \)\s
        #       client-ip=(?<client_ip>[^;]+);\s
        #       envelope-from=(?<envelope_from>[^;]+);\s
        #       helo=\[?(?<helo>[^;]+?)\]?;
        #     }x,
        #     %r{
        #       \A(?<result>\S+)\s
        #       \(
        #         (?<authserv_id>[^:]+):\s
        #         best\sguess\srecord\sfor\sdomain\sof\s(?<mailfrom>\S+)\s
        #         .+?
        #         \s(?<ip>\S+)\sas\spermitted\ssender
        #       \)\s
        #       client-ip=(?<client_ip>[^;]+);
        #     }x,
        #     %r{
        #       \A(?<result>\S+)\s
        #       \(
        #         (?<authserv_id>[^:]+):\s
        #         domain\sof\stransitioning\s(?<mailfrom>\S+)\s
        #         .+?
        #         \s(?<ip>\S+)\sas\spermitted\ssender
        #       \)\s
        #       client-ip=(?<client_ip>[^;]+);
        #     }x,
        #     %r{
        #       \A(?<result>\S+)\s
        #       \(
        #         (?<authserv_id>[^:]+):\s
        #         domain\sof\s(?<mailfrom>\S+)\s
        #         .+?
        #         \s(?<ip>\S+)\sas\spermitted\ssender
        #       \)\s
        #       receiver=(?<receiver>[^;]+);\s
        #       client-ip=(?<client_ip>[^;]+);\s
        #       helo=\[?(?<helo>[^;]+?)\]?;
        #     }x,
        #     %r{
        #       \A(?<result>\S+)\s
        #       \(
        #         (?<authserv_id>[^:]+):\s
        #         domain\sof\s(?<mailfrom>\S+)\s
        #         .+?
        #         \s(?<ip>\S+)\sas\spermitted\ssender
        #       \)\s
        #       client-ip=(?<client_ip>[^;]+);
        #     }x,
        #     %r{
        #       \A(?<result>\S+)\s
        #       \(
        #         (?<authserv_id>[^:]+):\s
        #         (?<ip>\S+)\sis\sneither\s
        #         .+?
        #         domain\sof\s(?<mailfrom>\S+)
        #       \)\s
        #       client-ip=(?<client_ip>[^;]+);
        #     }x
        #   ]
        #
        #   matches = patterns.inject(nil) do |memo, pattern|
        #     memo || value.match(pattern)
        #   end
        #
        #   if matches
        #     {
        #       result: matches[:result].downcase.to_sym,
        #       authserv_id: extract(matches, :authserv_id),
        #       mailfrom: extract(matches, :mailfrom),
        #       ip: @ip_factory.build(extract(matches, :ip)),
        #       client_ip: expand_ip(extract(matches, :client_ip)),
        #       receiver: extract(matches, :receiver),
        #       helo: expand_ip(extract(matches, :helo)),
        #       envelope_from: extract(matches, :envelope_from)
        #     }
        #   end
        # end

        private

        def parse_additional_data(data)
          patterns = [
            %r{
              (?<authserv_id>[^:]+):\s
              best\sguess\srecord\sfor\sdomain\sof\s(?<mailfrom>\S+)\s
              .+?
              \s(?<ip>\S+)\sas\spermitted\ssender
            }x,
            /domain\sof\s(?<mailfrom>\S+)\sdesignates\s(?<ip>\S+)\sas\spermitted\ssender/,
            /domain\sof\s(?<mailfrom>\S+)\sdoes\snot\sdesignate\spermitted\ssender\shosts/,
            %r{
              (?<authserv_id>[^:]+):\s
              transitioning\sdomain\sof\s(?<mailfrom>\S+)\s
              .+?
              \s(?<ip>\S+)\sas\spermitted\ssender
            }x,
            %r{
              (?<authserv_id>[^:]+):\s
              domain\sof\stransitioning\s(?<mailfrom>\S+)\s
                .+?
              \s(?<ip>\S+)\sas\spermitted\ssender
            }x,
            %r{
              (?<authserv_id>[^:]+):\s
              domain\sof\s(?<mailfrom>\S+)\s
                .+?
              \s(?<ip>\S+)\sas\spermitted\ssender
            }x,
            %r{
              (?<authserv_id>[^:]+):\s
              (?<ip>\S+)\sis\sneither\s
                .+?
              domain\sof\s(?<mailfrom>\S+)
            }x
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || data.match(pattern)
          end

          if matches
            {
              authserv_id: extract(matches, :authserv_id),
              mailfrom: extract(matches, :mailfrom),
              ip: @ip_factory.build(extract(matches, :ip)),
              # client_ip: expand_ip(extract(matches, :client_ip)),
              # receiver: extract(matches, :receiver),
              # helo: expand_ip(extract(matches, :helo)),
              # envelope_from: extract(matches, :envelope_from)
            }
          else
            {
              authserv_id: nil,
              mailfrom: nil,
              ip: nil,
            }
          end
        end

        def parse_attributes(attribute_data)
          output_template = {
            client_ip: nil, receiver: nil, helo: nil, envelope_from: nil, identity: nil
          }
          attribute_data.scan(/[^=]+=\S+/).inject(output_template) do |memo, attr_string|
            attribute, value = parse_attr_value(attr_string)
            if ['client_ip', 'helo'].include?(attribute)
              memo.merge(attribute.to_sym => expand_ip(value))
            else
              memo.merge(attribute.to_sym => value)
            end
          end
        end

        def parse_attr_value(attr_value_string)
          attribute, value = attr_value_string.strip.gsub(/[;\[\]]/, '').split('=')
          [attribute.gsub(/-/, '_'), value]
        end

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
