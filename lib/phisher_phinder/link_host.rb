# frozen-string_literal: true

module PhisherPhinder
  class LinkHost
    attr_accessor :url, :body, :status_code, :headers, :host_information

    def initialize(url:, body:, status_code:, headers:, host_information:)
      @url = url
      @body = body
      @status_code = status_code
      @headers = headers
      @host_information = host_information
    end

    def ==(other)
      url == other.url && body == other.body && status_code == other.status_code && headers == other.headers &&
        host_information == other.host_information
    end
  end
end
