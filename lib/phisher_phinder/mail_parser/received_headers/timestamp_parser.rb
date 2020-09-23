# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module ReceivedHeaders
      class TimestampParser
        def parse(timestamp)
          return {time: nil} unless timestamp

          require 'time'

          date_formats = [
            "%a, %d %b %Y %H:%M:%S %z (%Z)",
            "%a, %d %b %Y %H:%M:%S %z",
            "%d %b %Y %H:%M:%S %z"
          ]

          parsed_time = date_formats.inject(nil) do |parsed_time, pattern|
            begin
              parsed_time || Time.strptime(timestamp.strip, pattern)
            rescue ArgumentError
            end
          end

          raise "Could not match `#{timestamp}` with the available patterns" unless parsed_time

          {time: parsed_time}
        end
      end
    end
  end
end
