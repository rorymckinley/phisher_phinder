# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    class HeaderValueParser
      def parse(raw_value)
        if utf_8_preambles?(raw_value)
          (raw_value.split(' ').map { |snippet| parse_utf8_base64(snippet) }).join
        elsif windows_1251_preambles?(raw_value)
          (raw_value.split(' ').map { |snippet| parse_windows_1251_base64(snippet) }).join
        else
          raw_value.strip
        end
      end

      private

      def utf_8_preambles?(raw_value)
        raw_value.scan(/=\?UTF-8\?b\?/).any?
      end

      def windows_1251_preambles?(raw_value)
        raw_value.scan(/=\?windows-1251\?B\?/).any?
      end

      def parse_utf8_base64(raw_value)
        require 'base64'

        Base64.decode64(raw_value.strip.sub(/=\?UTF-8\?b\?/, '')).force_encoding('UTF-8')
      end

      def parse_windows_1251_base64(raw_value)
        require 'base64'

        Base64.decode64(raw_value.strip.sub(/=\?windows-1251\?B\?/, '')).force_encoding('cp1251').encode('UTF-8')
      end
    end
  end
end
