# frozen_string_literal: true

module Overphishing
  module MailParser
    module ReceivedHeaders
      class StarttlsParser
        def parse(component)
          return {starttls: nil} unless component

          matches = component.match(/\(version=(?<version>\S+)\scipher=(?<cipher>\S+)\sbits=(?<bits>\S+)\)/)

          {starttls: {version: matches[:version], cipher: matches[:cipher], bits: matches[:bits]}}
        end
      end
    end
  end
end
