# frozen_string_literal: true

module PhisherPhinder
  class NullLookupClient
    def lookup(_ip_address)
      NullResponse.new
    end
  end
end
