# frozen_string_literal: true

module PhisherPhinder
  class HostInformationFinder
    def initialize(whois_client:, extractor:)
      @whois_client = whois_client
      @extractor = extractor
    end

    def information_for(address)
      most_relevant_record = nil

      begin
        case address
        when ExtendedIp
          most_relevant_record = @whois_client.lookup(address.ip_address.to_s)
        when String
          hostname_parts = address.split('.')
          until most_relevant_record do
            address = hostname_parts.join('.')
            whois_record = @whois_client.lookup(address)
            if whois_record.parser.available?
              hostname_parts = hostname_parts[1..-1]
            else
              most_relevant_record = whois_record
            end
          end
        end
      rescue Whois::ServerNotFound
      rescue Whois::AttributeNotImplemented
      end

      {
        abuse_contacts: most_relevant_record ? @extractor.abuse_contact_emails(most_relevant_record.content) : [],
        creation_date: creation_date(most_relevant_record)
      }
    end

    private

    def creation_date(record)
      return nil unless record

      begin
        record.parser.created_on
      rescue Whois::AttributeNotImplemented, Whois::AttributeNotSupported
      end
    end
  end
end
