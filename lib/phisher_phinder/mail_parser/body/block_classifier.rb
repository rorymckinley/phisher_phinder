# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module Body
      class BlockClassifier
        def initialize(line_end)
          @line_end = line_end
        end

        def classify_block(contents)
          lines = contents.split(@line_end)
          processing_block_headers = true

          output = {
            content_type: :text,
            character_set: :utf_8,
            content_transfer_encoding: nil
          }

          while processing_block_headers do
            line = lines.shift.strip
            if line.empty?
              processing_block_headers = false
            elsif line =~ /\AContent-Type:/
              output.merge!(extract_content_type(line))

              output.merge!(extract_character_set(line))
            elsif line =~ /\AContent-Transfer-Encoding/
              output.merge!(extract_encoding(line))
            end
          end

          output[:content] = lines.join(@line_end)

          output
        end

        def classify_headers(headers)
          output = {
            content_type: :text,
            character_set: :utf_8,
            content_transfer_encoding: nil
          }

          output.merge!(extract_content_type(headers[:content_type]))

          output.merge!(extract_character_set(headers[:content_type]))

          output.merge!(extract_encoding(headers[:content_transfer_encoding]))

          output
        end

        private

        def extract_content_type(content_type_string)
          if content_type_string
            if content_type_string.include?('text/plain')
              {content_type: :text}
            elsif content_type_string.include?('text/html')
              {content_type: :html}
            else
              {}
            end
          else
            {}
          end
        end

        def extract_character_set(content_type_string)
          if content_type_string
            charset_matches = content_type_string.match(/charset="?(?<charset>.+?)"?\z/)
            if charset_matches
              if charset_matches[:charset].downcase == 'utf-8'
                {character_set: :utf_8}
              elsif charset_matches[:charset].downcase == 'windows-1251'
                {character_set: :windows_1251}
              elsif charset_matches[:charset].downcase == 'iso-8859-1'
                {character_set: :iso_8859_1}
              else
                {}
              end
            else
              {}
            end
          else
            {}
          end
        end

        def extract_encoding(encoding_string)
          if encoding_string&.include? 'base64'
            {content_transfer_encoding: :base64}
          elsif encoding_string&.include? 'quoted-printable'
            {content_transfer_encoding: :quoted_printable}
          elsif encoding_string&.include? '7bit'
            {content_transfer_encoding: :seven_bit}
          else
            {}
          end
        end
      end
    end
  end
end
