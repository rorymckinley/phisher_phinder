# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module AuthenticationHeaders
      class AuthResultsParser
        def initialize(ip_factory:)
          @ip_factory = ip_factory
        end

        def parse(value)
          authserv_id, results = value.split(';', 2)

          {
            authserv_id: authserv_id
          }.merge(spf_data(value)).merge(dkim_data(value)).merge(iprev_data(value)).merge(auth_data(value))
        end

        private

        def spf_data(value)
          patterns = [
            %r{
              spf=(?<result>[\S]+)\s
              \([^:]+:\s(?<ip>[\S]+)\sis\sneither\spermitted[^\)]+\)\s
              smtp.mailfrom=(?<from>[^\s;]+)
            }x,
            %r{
              spf=(?<result>[\S]+)\s
              \(.+\s(?<ip>[\S]+)\sas\spermitted.+\)\s
              smtp.mailfrom=(?<from>[^\s;]+)
            }x,
            %r{
              spf=(?<result>[\S]+)\ssmtp.mailfrom=(?<from>[^\s;]+)
            }x,
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || value.match(pattern)
          end

          if matches
            {
              spf: {
                result: matches[:result].to_sym,
                ip: matches.names.include?('ip') ? @ip_factory.build(matches[:ip]) : nil,
                from: matches[:from]
              }
            }
          else
            {}
          end
        end

        def dkim_data(value)
          matches = value.match(
            /
            dkim=(?<result>[\S]+)\s.*?
            header.i=(?<identity>[\S]+)\s
            header.s=(?<selector>[\S]+)\s
            header.b=(?<hash_snippet>.{8})
            /x
          )

          if matches
            {
              dkim: {
                result: matches[:result].to_sym,
                identity: matches[:identity],
                selector: matches[:selector],
                hash_snippet: matches[:hash_snippet]
              }
            }
          else
            {}
          end
        end

        def iprev_data(value)
          matches = value.match(
            /
            iprev=(?<result>[\S]+)\s
            \((?<remote_host_name>[^\)]+)\)\s
            smtp.remote-ip=(?<remote_ip>[^\s;]+)
            /x
          )

          if matches
            {
              iprev: {
                result: matches[:result].to_sym,
                remote_host_name: matches[:remote_host_name],
                remote_ip: @ip_factory.build(matches[:remote_ip]),
              }
            }
          else
            {}
          end
        end

        def auth_data(value)
          matches = value.match(/auth=(?<result>[\S]+)\s.+smtp.auth=(?<domain>[^\s;]+)/)

          if matches
            {
              auth: {
                result: matches[:result].to_sym,
                domain: matches[:domain],
              }
            }
          else
            {}
          end
        end
      end
    end
  end
end
