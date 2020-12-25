# frozen_string_literal: true

module PhisherPhinder
  class SenderExtractor
    def extract(mail)
      auth_senders = {
        hosts: [],
        email_addresses: []
      }

      processed_authservs = []

      authentication_results = mail.authentication_headers[:authentication_results]

      if authentication_results.any?
        trusted_auth_header = authentication_results.first
        untrusted_auth_headers = authentication_results[1..-1]

        auth_senders[:hosts] << {
          entry_type: :ip,
          host: trusted_auth_header[:spf].first[:ip],
          spf: {present: true, trusted: true}
        }
        auth_senders[:email_addresses] << {
          email_address: trusted_auth_header[:spf].first[:from],
          spf: {present: true, trusted: true, result: trusted_auth_header[:spf].first[:result]},
        }

        processed_authservs << trusted_auth_header[:authserv_id]

        untrusted_auth_headers.each do |header|
          next if processed_authservs.include? header[:authserv_id]

          auth_senders[:hosts] << {entry_type: :ip, host: header[:spf].first[:ip], spf: {present: true, trusted: false}}
          unless auth_senders[:email_addresses].find { |entry| entry[:email_address] == header[:spf].first[:from] }
            auth_senders[:email_addresses] << {
              email_address: header[:spf].first[:from],
              spf: {present: true, trusted: false, result: header[:spf].first[:result]},
            }
          end
        end
      end

      tracing_senders = []

      mail.tracing_headers[:received].each do |header|
        if tracing_senders.empty?
          if header[:sender] && header[:sender][:ip] == trusted_auth_sender_ip(auth_senders)
            tracing_senders << header[:sender]
          end

          next
        end

        if header[:sender] && header[:recipient] == tracing_senders.last[:host]
          tracing_senders << header[:sender]
        else
          break
        end
      end

      {
        authentication_senders: auth_senders,
        tracing_senders: tracing_senders
      }
    end

    private

    def trusted_auth_sender_ip(authentication_senders)
      (authentication_senders[:hosts].find { |e| e[:spf][:trusted] })[:host]
    end
  end
end
