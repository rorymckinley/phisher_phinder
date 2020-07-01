Sequel.migration do
  change do
    create_table(:geoip_ip_data) do
      primary_key :id
      String :ip_address
      Integer :location_accuracy_radius
      Float :latitude
      Float :longitude
      String :time_zone
      String :city_name
      String :city_geoname_id
      Integer :city_confidence
      String :country_name
      String :country_geoname_id
      String :country_iso_code
      Integer :country_confidence
      String :continent_name
      String :continent_geoname_id
      String :postal_code
      Integer :postal_code_confidence
      String :registered_country_name
      String :registered_country_geoname_id
      String :registered_country_iso_code
      String :autonomous_system_organisation
      Integer :autonomous_system_number
      String :isp
      String :network
      String :organisation
      String :static_ip_score
      String :user_type
      Time :created_at, null: false
      Time :updated_at, null: false
    end
  end
end
