# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module ReceivedHeaders
      class ForParser
        def initialize(starttls_parser:)
          @starttls_parser = starttls_parser
        end

        def parse(component)
          return {recipient_mailbox: nil}.merge(@starttls_parser.parse(nil)) unless component

          patterns = [
            /\Afor\s(?<recipient_mailbox>\S+)\s\(Google Transport Security\)\z/,
            /\Afor\s(?<recipient_mailbox>\S+)\s(?<starttls>\([^\)]+\))\z/,
            /\Afor\s(?<recipient_mailbox>.+)\z/,
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || component.match(pattern)
          end

          output = {
            recipient_mailbox: strip_angle_brackets(matches[:recipient_mailbox]),
          }.merge(
            if matches.names.include?('starttls')
              @starttls_parser.parse(matches[:starttls])
            else
              @starttls_parser.parse(nil)
            end
          )
        end

        private

        def strip_angle_brackets(email_address_string)
          email_address_string =~ /\<\s?([^>]+?)\s?\>/ ? $1 : email_address_string
        end
      end
    end
  end
end
