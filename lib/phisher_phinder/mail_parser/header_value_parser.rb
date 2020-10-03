# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    class HeaderValueParser
      def parse(raw_value)
        stripped_value = raw_value.strip
        words = stripped_value.split(' ')
        words.map do |word|
          if encoded?(word)
            matches = word.match(/\A=\?(?<character_set>.+)\?(?<encoding>.)\?(?<content>.+)\z/)

            unencoded_content = if matches[:encoding].downcase == 'b'
                                  Base64.decode64(matches[:content])
                                elsif matches[:encoding].downcase == 'q'
                                  matches[:content].unpack('M').first
                                end

            content = if matches[:character_set] =~ /iso-8859-1/i
                        unencoded_content.force_encoding('ISO-8859-1').encode('UTF-8')
                      elsif matches[:character_set] =~ /windows-1251/i
                        unencoded_content.force_encoding('cp1251').encode('UTF-8')
                      elsif matches[:character_set] =~ /utf-8/i
                        unencoded_content.force_encoding('UTF-8')
                      end
          else
            word
          end
        end.join(' ')
      end

      private

      def encoded?(raw_value)
        raw_value =~ /=\?[a-z1-9-]+\?[bq]/i
      end
    end
  end
end
