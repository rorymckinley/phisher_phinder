# frozen_string_literal: true
require 'excon'

module PhisherPhinder
  class LinkExplorer
    def initialize(host_information_finder:, host_response_policy:)
      @host_information_finder = host_information_finder
      @host_response_policy = host_response_policy
    end

    def explore(hyperlink)
      if hyperlink.type == :url
        chain_terminated = false
        url = hyperlink.href
        output = []

        until chain_terminated do
          result = Excon.get(url.to_s)

          output << LinkHost.new(
            url: url,
            body: result.body,
            headers: result.headers,
            status_code: result.status,
            host_information: @host_information_finder.information_for("#{url.scheme}://#{url.host}"),
          )

          unless url = @host_response_policy.next_url(result)
            chain_terminated = true
          end
        end

        output
      else
        hyperlink.href =~ /mailto:(.+)/
        ($1.split(';').map { |address| address.strip }).uniq
      end
    end
  end
end
