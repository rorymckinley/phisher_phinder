# frozen_string_literal: true

RSpec.describe Overphishing::SimpleIp do
  it 'considers two instances to be equal if they both have the same ip address' do
    expect(described_class.new(ip_address: '127.0.0.1')).to eq(described_class.new(ip_address: '127.0.0.1'))
    expect(described_class.new(ip_address: '127.0.0.2')).to_not eq(described_class.new(ip_address: '127.0.0.1'))
    expect(described_class.new(ip_address: '127.0.0.1')).to_not eq(
      Overphishing::ExtendedIp.new(ip_address: '127.0.0.1', geoip_ip_data: nil)
    )
  end
end
