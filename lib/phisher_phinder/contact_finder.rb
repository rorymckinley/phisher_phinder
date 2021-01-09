# frozen_string_literal: true

module PhisherPhinder
  class ContactFinder
    def initialize(whois_client:, extractor:)
      @whois_client = whois_client
      @extractor = extractor
    end

    def contacts_for(address)
      whois_content = nil
      begin
        whois_content = case address
                        when ExtendedIp
                          @whois_client.lookup(address.ip_address.to_s).content
                        when String
                          hostname_parts = address.split('.')
                          whois_content = nil
                          until whois_content do
                            address = hostname_parts.join('.')
                            whois_record = @whois_client.lookup(address)
                            if whois_record.parser.available?
                              hostname_parts = hostname_parts[1..-1]
                            else
                              whois_content = whois_record.content
                            end
                          end
                          whois_content
                        end
      rescue Whois::ServerNotFound
      rescue Whois::AttributeNotImplemented
      end

      whois_content ? @extractor.abuse_contact_emails(whois_content) : []
    end
  end
end
