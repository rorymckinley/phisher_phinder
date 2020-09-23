# frozen_string_literal

module PhisherPhinder
  class SimpleIp
    attr_reader :ip_address

    def initialize(ip_address:)
      @ip_address = ip_address
    end

    def ==(other)
      other.is_a?(SimpleIp) && ip_address == other.ip_address
    end
  end
end
