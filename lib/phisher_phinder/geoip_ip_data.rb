# frozen_string_literal: true

if ENV['DATABASE_URL']
  require 'sequel'
  Sequel::Model.plugin :timestamps, update_on_create: true

  DB = Sequel.connect(ENV.fetch('DATABASE_URL'))

  module PhisherPhinder
    class GeoipIpData < Sequel::Model(:geoip_ip_data)
    end
  end
end
