# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module AuthenticationHeaders
      class Parser
        def initialize(authentication_results_parser:)
          @authentication_results_parser = authentication_results_parser
        end

        def parse(headers)
          {
            authentication_results: (headers[:authentication_results] || []).map do |header|
              @authentication_results_parser.parse(header[:data])
            end
          }
        end
      end
    end
  end
end
