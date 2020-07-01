# frozen_string_literal: true

module Overphishing
  class CachedGeoipClient
    def initialize(client, expiry_time)
      @client = client
      @expiry_time = expiry_time
      @lang = 'en'
    end

    def lookup(ip_address)
      cached_record = retrieve_cached_record(ip_address)
      if cached_record && cached_record_valid?(cached_record)
        cached_record
      else
        refresh_cache(ip_address, cached_record)
      end
    end

    private

    def retrieve_cached_record(ip_address)
      Overphishing::GeoipIpData.first(ip_address: ip_address)
    end

    def cached_record_valid?(cached_record)
      cached_record.updated_at > @expiry_time
    end

    def refresh_cache(ip_address, cached_record)
      lookup_result = @client.insights(ip_address)

      if cached_record
        cached_record.update(
          location_accuracy_radius: lookup_result.location.accuracy_radius,
          latitude: lookup_result.location.latitude,
          longitude: lookup_result.location.longitude,
          time_zone: lookup_result.location.time_zone,
          city_name: lookup_result.city.names[@lang],
          city_geoname_id: lookup_result.city.geoname_id,
          city_confidence: lookup_result.city.confidence,
          country_name: lookup_result.country.names[@lang],
          country_geoname_id: lookup_result.country.geoname_id,
          country_iso_code: lookup_result.country.iso_code,
          country_confidence: lookup_result.country.confidence,
          continent_name: lookup_result.continent.names[@lang],
          continent_geoname_id: lookup_result.continent.geoname_id,
          postal_code: lookup_result.postal.code,
          postal_code_confidence: lookup_result.postal.confidence,
          registered_country_name: lookup_result.registered_country.names[@lang],
          registered_country_geoname_id: lookup_result.registered_country.geoname_id,
          registered_country_iso_code: lookup_result.registered_country.iso_code,
          autonomous_system_organisation: lookup_result.traits.autonomous_system_organization,
          autonomous_system_number: lookup_result.traits.autonomous_system_number,
          isp: lookup_result.traits.isp,
          network: lookup_result.traits.network,
          organisation: lookup_result.traits.organization,
          static_ip_score: lookup_result.traits.static_ip_score,
          user_type: lookup_result.traits.user_type
        )
      else
        Overphishing::GeoipIpData.create(
          ip_address: ip_address,
          location_accuracy_radius: lookup_result.location.accuracy_radius,
          latitude: lookup_result.location.latitude,
          longitude: lookup_result.location.longitude,
          time_zone: lookup_result.location.time_zone,
          city_name: lookup_result.city.names[@lang],
          city_geoname_id: lookup_result.city.geoname_id,
          city_confidence: lookup_result.city.confidence,
          country_name: lookup_result.country.names[@lang],
          country_geoname_id: lookup_result.country.geoname_id,
          country_iso_code: lookup_result.country.iso_code,
          country_confidence: lookup_result.country.confidence,
          continent_name: lookup_result.continent.names[@lang],
          continent_geoname_id: lookup_result.continent.geoname_id,
          postal_code: lookup_result.postal.code,
          postal_code_confidence: lookup_result.postal.confidence,
          registered_country_name: lookup_result.registered_country.names[@lang],
          registered_country_geoname_id: lookup_result.registered_country.geoname_id,
          registered_country_iso_code: lookup_result.registered_country.iso_code,
          autonomous_system_organisation: lookup_result.traits.autonomous_system_organization,
          autonomous_system_number: lookup_result.traits.autonomous_system_number,
          isp: lookup_result.traits.isp,
          network: lookup_result.traits.network,
          organisation: lookup_result.traits.organization,
          static_ip_score: lookup_result.traits.static_ip_score,
          user_type: lookup_result.traits.user_type
        )
      end
    end
  end
end
