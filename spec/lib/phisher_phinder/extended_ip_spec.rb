# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::ExtendedIp do
  let(:geoip_data_1) do
    PhisherPhinder::GeoipIpData.create(ip_address: '99.99.99.98')
  end
  let(:geoip_data_2) do
    PhisherPhinder::GeoipIpData.create(ip_address: '99.99.99.99')
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

  it 'returns the ip address as a string when to_s is called' do
    expect(subject.to_s).to eql ip_address_1.to_s
  end
end
