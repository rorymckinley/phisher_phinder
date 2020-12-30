# frozen_string_literal: true

module PhisherPhinder
  class TracingReport
    def initialize(mail)
      @mail = mail
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
        tracing: extract_tracing_headers(@mail.tracing_headers, latest_spf_entry)
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
      received_headers[:received][start..-1]
    end
  end
end
