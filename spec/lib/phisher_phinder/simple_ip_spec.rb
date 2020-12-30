# frozen_string_literal: true

RSpec.describe PhisherPhinder::SimpleIp do
  it 'considers two instances to be equal if they both have the same ip address' do
    expect(described_class.new(ip_address: '127.0.0.1')).to eq(described_class.new(ip_address: '127.0.0.1'))
    expect(described_class.new(ip_address: '127.0.0.2')).to_not eq(described_class.new(ip_address: '127.0.0.1'))
    expect(described_class.new(ip_address: '127.0.0.1')).to_not eq(
      PhisherPhinder::ExtendedIp.new(ip_address: '127.0.0.1', geoip_ip_data: nil)
    )
  end

  it 'returns the ip address when to_s is called' do
    expect(described_class.new(ip_address: '127.0.0.1').to_s).to eql '127.0.0.1'
  end
end
