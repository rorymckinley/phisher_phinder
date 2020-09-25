# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module Body
      class BlockParser
        def parse(block_data)
          encoding = block_data[:content_transfer_encoding] || :seven_bit

          case encoding
          when :seven_bit
            block_data[:content]
          when :base64
            decoded = Base64.decode64(block_data[:content])
            if block_data[:character_set] == :utf_8
              decoded.force_encoding('UTF-8')
            elsif block_data[:character_set] == :windows_1251
              decoded.force_encoding('cp1251').encode('UTF-8')
            end
          when :quoted_printable
            block_data[:content].unpack('M').first.force_encoding('UTF-8')
          end
        end
      end
    end
  end
end
