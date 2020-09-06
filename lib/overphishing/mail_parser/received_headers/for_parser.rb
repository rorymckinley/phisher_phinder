# frozen_string_literal: true

module Overphishing
  module MailParser
    module ReceivedHeaders
      class ForParser
        def parse(component)
          component =~ /\Afor\s(\S+)\z/

          {
            recipient_mailbox: strip_angle_brackets($1)
          }
        end

        private

        def strip_angle_brackets(email_address_string)
          email_address_string =~ /\<([^>]+)\>/ ? $1 : email_address_string
        end
      end
    end
  end
end
