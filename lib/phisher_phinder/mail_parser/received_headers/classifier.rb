# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module ReceivedHeaders
      class Classifier
        def classify(header_data)
          {partial: !complete?(header_data)}
        end

        private

        def complete?(header_data)
          (
            header_data[:advertised_sender] &&
            header_data[:recipient] &&
            header_data[:recipient_mailbox] &&
            (
              (header_data[:protocol] == 'ESMTPS' && header_data[:starttls]) ||
              (header_data[:protocol] != 'ESMTPS' && !header_data[:starttls])
            )
          )
        end
      end
    end
  end
end
