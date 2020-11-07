# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module AuthenticationHeaders
      class AuthResultsParser
        def initialize(ip_factory:)
          @ip_factory = ip_factory
        end

        def parse(value)
          authserv_id, results = value.split(';')

          {
            authserv_id: authserv_id
          }.merge(spf_data(value))
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
      end
    end
  end
end
