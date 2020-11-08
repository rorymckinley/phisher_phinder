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
          }.merge(spf_data(value)).merge(dkim_data(value))
        end

        private

        def spf_data(value)
          matches = value.match(/
                                spf=(?<result>[\S]+)\s
                                \(.*\s(?<ip>\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})\s.*\)\s
                                smtp.mailfrom=(?<from>[^\s;]+)
                                /x)

          {
            spf: {
              result: matches[:result].to_sym,
              ip: @ip_factory.build(matches[:ip]),
              from: matches[:from]
            }
          }
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
      end
    end
  end
end
