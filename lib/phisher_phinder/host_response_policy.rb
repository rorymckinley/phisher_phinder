# frozen_string_literal: true

module PhisherPhinder
  class HostResponsePolicy
    def next_url(url, response)
      location_header = response.headers['Location']

      if [301, 302, 303, 307, 308].include?(response.status) && location_header && !location_header.empty?
        if response.headers['Location'] =~ %r{\A/}
          url.merge(response.headers['Location'])
        else
          URI.parse(response.headers['Location'])
        end
      end
    end
  end
end
