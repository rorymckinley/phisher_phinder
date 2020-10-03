# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    class BodyParser
      def initialize(line_end)
        @line_end = line_end
      end

      def parse(body_contents:, content_type:, content_transfer_encoding:)
        if multipart_alternative?(content_type)
          parse_multipart_alternative(content_type, body_contents)
        else
          classifier = Body::BlockClassifier.new(@line_end)
          parser = Body::BlockParser.new(@line_end)

          classification = classifier.classify_headers(
            content_type: content_type, content_transfer_encoding: content_transfer_encoding
          ).merge(content: body_contents)

          contents = parser.parse(classification)

          if classification[:content_type] == :html
            {
              html: contents,
              text: nil
            }
          else
            {
              html: nil,
              text: contents
            }
          end
        end
      end

      private

      def html?(content_type)
        content_type && content_type.split(';').first == 'text/html'
      end

      def decode_body(body_contents, content_transfer_encoding)
        require 'base64'

        content_transfer_encoding ? Base64.decode64(body_contents) : body_contents
      end

      def multipart_alternative?(content_type)
        content_type =~ /\Amultipart\/alternative/
      end

      def parse_multipart_alternative(content_type, contents)
        base_boundary = content_type.split(';').last.strip.split('=').last.gsub(/"/, '')
        start_boundary = '--' + base_boundary + @line_end
        end_boundary = '--' + base_boundary + '--'

        raw_blocks = contents.split(start_boundary)
        trimmed_blocks = strip_epilogue(strip_prologue(raw_blocks), end_boundary)

        categorise_blocks(trimmed_blocks).inject({html: '', text: ''}) do |memo, block|
          memo.merge(block[:html] ? {html: memo[:html] + block[:contents]} : {text: memo[:text] + block[:contents]})
        end
      end

      def strip_prologue(blocks)
        blocks[1..-1]
      end

      def strip_epilogue(blocks, end_boundary)
        blocks[0..-2] << blocks[-1].split(end_boundary).first
      end

      def categorise_blocks(blocks)
        classifier = Body::BlockClassifier.new(@line_end)
        parser = Body::BlockParser.new(@line_end)
        blocks.map do |block|
          classification = classifier.classify_block(block)
          contents = parser.parse(classification)

          {
            html: classification[:content_type] == :html,
            contents: contents
          }
        end
      end
    end
  end
end
