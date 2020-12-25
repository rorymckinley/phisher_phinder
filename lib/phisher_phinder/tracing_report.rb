# frozen_string_literal: true

module PhisherPhinder
  class TracingReport
    def report(mail)
      trusted_auth_header = mail.authentication_headers[:authentication_results].first

      {
        authentication: {
          mechanisms: [:spf],
          spf: {
            success: trusted_auth_header[:spf].first[:result] == :pass,
            ip: trusted_auth_header[:spf].first[:ip],
            from_address: trusted_auth_header[:spf].first[:from]
          }
        },
        tracing: extract_tracing_headers(mail.tracing_headers, trusted_auth_header)
      }
    end

    private

    def extract_tracing_headers(received_headers, trusted_auth_header)
      start = received_headers[:received].find_index { |h| h[:sender][:ip] == trusted_auth_header[:spf].first[:ip] }
      received_headers[:received][start..-1]
    end
  end
end
