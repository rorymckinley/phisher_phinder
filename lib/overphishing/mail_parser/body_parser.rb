# frozen_string_literal: true

module Overphishing
  module MailParser
    class BodyParser
      def initialize(line_end)
        @line_end = line_end
      end

      def parse(body_contents:, content_type:, content_transfer_encoding:)
        if multipart_alternative?(content_type)
          parse_multipart_alternative(content_type, body_contents)
        elsif html?(content_type)
          {
            text: nil,
            html: decode_body(body_contents, content_transfer_encoding)
          }
        else
          {
            text: body_contents,
            html: nil
          }
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
        base_boundary = content_type.split(';').last.strip.split('=').last
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
        blocks.map do |block|
          lines = block.split(@line_end)
          processing_block_headers = true
          html = false
          base64_encoded = false

          while processing_block_headers do
            line = lines.shift.strip
            if line.empty?
              processing_block_headers = false
            elsif line =~/\AContent-Type: text\/html/
              html = true
            elsif line =~ /\AContent-Transfer-Encoding: base64/
              base64_encoded = true
            end
          end

          contents = if base64_encoded
                       (lines.map { |l| Base64.decode64(l) }).join
                     else
                       lines.join(@line_end)
                     end
          {
            html: html,
            contents: contents
          }
        end
      end
    end
  end
end
