# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    class HeaderValueParser
      def parse(raw_value)
        utf_8_preambles = raw_value.scan(/=\?UTF-8\?b\?/)
        if raw_value.scan(/=\?UTF-8\?b\?/).any?
          (raw_value.split(' ').map { |snippet| parse_utf8_base64(snippet) }).join
        else
          raw_value.strip
        end
      end

      private

      def parse_utf8_base64(raw_value)
        require 'base64'

        Base64.decode64(raw_value.strip.sub(/=\?UTF-8\?b\?/, '')).force_encoding('UTF-8')
      end
    end
  end
end
