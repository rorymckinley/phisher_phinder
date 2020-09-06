# frozen_string_literal: true

module Overphishing
  module MailParser
    module ReceivedHeaders
      class TimestampParser
        def parse(timestamp)
          return {time: nil} unless timestamp

          require 'time'

          {time: Time.strptime(timestamp.strip, "%a, %d %b %Y %H:%M:%S %z (%Z)")}
        rescue ArgumentError
          {time: Time.strptime(timestamp.strip, "%a, %d %b %Y %H:%M:%S %z")}
        end
      end
    end
  end
end
