# frozen_string_literal: true

module PhisherPhinder
  class ExtendedIp
    attr_reader :ip_address, :geoip_ip_data

    def initialize(ip_address:, geoip_ip_data:)
      @ip_address = ip_address
      @geoip_ip_data = geoip_ip_data
    end

    def ==(other)
      ip_address == other.ip_address && geoip_ip_data == other.geoip_ip_data
    end

    def to_s
      @ip_address.to_s
    end
  end
end
