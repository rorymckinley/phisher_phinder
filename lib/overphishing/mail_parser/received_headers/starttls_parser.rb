# frozen_string_literal: true

module Overphishing
  module MailParser
    module ReceivedHeaders
      class StarttlsParser
        def parse(component)
          return {starttls: nil} unless component

          patterns = [
            /\(version=(?<version>\S+)\scipher=(?<cipher>\S+)\sbits=(?<bits>\S+)\)/,
            /using\s(?<version>\S+)\swith cipher\s(?<cipher>\S+)\s\((?<bits>.+?) bits\)/
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || component.match(pattern)
          end

          {starttls: {version: matches[:version], cipher: matches[:cipher], bits: matches[:bits]}}
        end
      end
    end
  end
end
