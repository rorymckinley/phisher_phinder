# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Overphishing::CachedGeoipClient do
  let(:client) { instance_double(MaxMind::GeoIP2::Client, insights: insight) }
  let(:expiry_time) { Time.now - 60 }
  let(:insight) do
    MaxMind::GeoIP2::Model::Insights.new(record, ["en"])
  end
  let(:record) do
    {
      "city" => {
        "confidence" => 90,
        "geoname_id" => 3369157,
        "names" => {"en" => "Cape Town"}
      },
      "continent" => {
        "code" => "AF",
        "geoname_id" => 6255146,
        "names" => {"en" => "Africa"}
      },
      "country" => {
        "confidence" => 99,
        "iso_code" => "ZA",
        "geoname_id" => 953987,
        "names" => {"en" => "South Africa"}
      },
      "location" => {
        "accuracy_radius" => 20,
        "latitude" => -33.9165,
        "longitude" => 18.4155,
        "time_zone" => "Africa/Johannesburg"
      },
      "maxmind" => {
        "queries_remaining" => 6632
      },
      "postal" => {
        "confidence" => 1,
        "code" => "7700"
      },
      "registered_country" => {
        "iso_code" => "ZA",
        "geoname_id" => 953987,
        "names" => {
          "en"=>"South Africa"
        }
      },
      "subdivisions" => [
        {
          "confidence" => 99,
          "iso_code" => "WC",
          "geoname_id" => 1085599,
          "names" => {
            "en" => "Western Cape"
          }
        }
      ],
      "traits"=> {
        "static_ip_score" => 21.5,
        "user_count" => 1,
        "user_type" => "residential",
        "autonomous_system_number" => 9999,
        "autonomous_system_organization" => "FOO-CORP",
        "domain" => "foocorp.co.za",
        "isp" => "foo-corp",
        "organization" => "foocorp",
        "ip_address" => "1.1.1.1",
        "network" => "1.1.1.1/32"
      }
    }
  end
  describe 'no entry in the database' do
    subject { described_class.new(client, expiry_time) }

    it 'queries the geoip service to get data for the ip address' do
      expect(client).to receive(:insights).with('1.1.1.1')

      subject.lookup('1.1.1.1')
    end

    it 'persists a geoip ip data instance' do
      expect { subject.lookup('1.1.1.1') }.to change(Overphishing::GeoipIpData, :count).by(1)

      record = Overphishing::GeoipIpData.first

      expect(record.ip_address).to eql '1.1.1.1'
      expect(record.location_accuracy_radius).to eql 20
      expect(record.latitude).to eql -33.9165
      expect(record.longitude).to eql 18.4155
      expect(record.time_zone).to eql 'Africa/Johannesburg'
      expect(record.city_name).to eql "Cape Town"
      expect(record.city_geoname_id).to eql '3369157'
      expect(record.city_confidence).to eql 90
      expect(record.country_name).to eql 'South Africa'
      expect(record.country_geoname_id).to eql '953987'
      expect(record.country_iso_code).to eql 'ZA'
      expect(record.country_confidence).to eql 99
      expect(record.continent_name).to eql 'Africa'
      expect(record.continent_geoname_id).to eql '6255146'
      expect(record.postal_code).to eql '7700'
      expect(record.postal_code_confidence).to eql 1
      expect(record.registered_country_name).to eql 'South Africa'
      expect(record.registered_country_geoname_id).to eql '953987'
      expect(record.registered_country_iso_code).to eql 'ZA'
      expect(record.autonomous_system_organisation).to eql 'FOO-CORP'
      expect(record.autonomous_system_number).to eql 9999
      expect(record.isp).to eql 'foo-corp'
      expect(record.network).to eql '1.1.1.1/32'
      expect(record.organisation).to eql 'foocorp'
      expect(record.static_ip_score).to eql '21.5'
      expect(record.user_type).to eql 'residential'
    end

    it 'returns a persisted record rather than performing a lookup if a record exists' do
      Overphishing::GeoipIpData.create(
        ip_address: '1.1.1.1', country_name: "People's Republic of Hout Bay", updated_at: expiry_time
      )

      expect(client).to_not receive(:insights)

      record = subject.lookup('1.1.1.1')

      expect(record.country_name).to eql  "People's Republic of Hout Bay"
    end

    it 'replaces a persisted record if the record was last updated outside the expiry window', :aggregate_failures do
      persisted_record = Overphishing::GeoipIpData.create(
        ip_address: '1.1.1.1', country_name: "People's Republic of Hout Bay"
      )
      persisted_record.this.update(updated_at: expiry_time - 1)

      record = subject.lookup('1.1.1.1')

      expect(persisted_record.reload.country_name).to eql 'South Africa'
      expect(record.country_name).to eql 'South Africa'
    end

    it 'replaces a persisted record if the record was last updated on the edge of the expiry window', :aggregate_failures do
      persisted_record = Overphishing::GeoipIpData.create(
        ip_address: '1.1.1.1', country_name: "People's Republic of Hout Bay"
      )
      persisted_record.this.update(updated_at: expiry_time)

      record = subject.lookup('1.1.1.1')

      expect(persisted_record.reload.country_name).to eql 'South Africa'
      expect(record.country_name).to eql 'South Africa'
    end

  end
end
