# frozen_string_literal: true

module PhisherPhinder
  class TracingReport
    def initialize(mail:, host_information_finder:, link_explorer:)
      @mail = mail
      @host_information_finder = host_information_finder
      @link_explorer = link_explorer
    end

    def report
      {
        authentication: {
          mechanisms: [:spf],
          spf: {
            success: latest_spf_entry[:result] == :pass,
            ip: latest_spf_entry[:ip],
            from_address: latest_spf_entry[:mailfrom],
            client_ip: latest_spf_entry[:client_ip],
          }
        },
        origin: extract_origin_headers(@mail.headers),
        tracing: extract_tracing_headers(@mail.tracing_headers, latest_spf_entry),
        content: {
          linked_urls: explore_hyperlinks(@mail.hypertext_links),
        },
      }
    end

    private

    def latest_spf_entry
      @mail.authentication_headers[:received_spf].first
    end

    def ip_address(spf_entry)
      spf_entry[:ip] || spf_entry[:client_ip]
    end

    def extract_tracing_headers(received_headers, latest_spf_entry)
      start = received_headers[:received].find_index { |h| h[:sender][:ip] == ip_address(latest_spf_entry) }
      received_headers[:received][start..-1].map do |h|
        h.merge(
          sender_contact_details: {
            host: {
              email: @host_information_finder.information_for(
                h[:sender][:host]
              )[:abuse_contacts]
            },
            ip: {
              email: @host_information_finder.information_for(
                h[:sender][:ip]
              )[:abuse_contacts]
            },
          }
        )
      end
    end

    def extract_origin_headers(headers)
      [:from, :return_path, :message_id].inject({}) do |output, header_type|
        entries = headers[header_type] || []
        output.merge(header_type => entries.map { |h| h[:data] })
      end
    end

    def explore_hyperlinks(hyperlinks)
      (hyperlinks.uniq { |link| link.href }).map { |hyperlink| @link_explorer.explore(hyperlink) }
    end
  end
end
