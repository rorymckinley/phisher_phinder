# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Overphishing::ExtendedIp do
  let(:geoip_data_1) do
    Overphishing::GeoipIpData.create(ip_address: '99.99.99.98')
  end
  let(:geoip_data_2) do
    Overphishing::GeoipIpData.create(ip_address: '99.99.99.99')
  end
  let(:ip_address_1) { IPAddr.new('99.99.99.98') }
  let(:ip_address_2) { IPAddr.new('99.99.99.99') }

  subject { described_class.new(ip_address: ip_address_1, geoip_ip_data: geoip_data_1) }

  it 'is equal if it has the same address and geoip_data instance' do
    geoip_data_1
    geoip_data_2

    expect(subject).to eq described_class.new(ip_address: ip_address_1, geoip_ip_data: geoip_data_1)
    expect(subject).to_not eq described_class.new(ip_address: ip_address_2, geoip_ip_data: geoip_data_1)
    expect(subject).to_not eq described_class.new(ip_address: ip_address_1, geoip_ip_data: geoip_data_2)
  end
end
