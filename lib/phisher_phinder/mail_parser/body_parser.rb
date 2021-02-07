# frozen_string_literal: true
require 'mail'

module PhisherPhinder
  module MailParser
    class BodyParser
      def parse(contents)
        mail = ::Mail.new(contents)
        aggregate_body_parts(mail)
      end

      private

      def aggregate_body_parts(mail)
        accumulator = {text: [], html: []}
        if mail.body.parts.any?
          collapse_content(mail.body, accumulator)
          accumulator.inject({}) { |accum, (type, parts)| accum.merge(type => parts.join) }
        else
          {
            text: mail.body.decoded,
            html: nil
          }
        end
      end

      def collapse_content(part, accumulator)
        if part.parts.any?
          part.parts.each { |p| collapse_content(p, accumulator) }
        elsif part.content_type =~ %r{text/plain}
          accumulator[:text] << part.decoded
        elsif part.content_type =~ %r{text/html}
          accumulator[:html] << part.decoded
        end
      end
    end
  end
end
