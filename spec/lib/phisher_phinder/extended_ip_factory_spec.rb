# frozen_string_literal: true
require 'spec_helper'
require 'ipaddr'

RSpec.describe PhisherPhinder::ExtendedIpFactory do
  describe '#build' do
    let(:geoip_client) { instance_double(PhisherPhinder::CachedGeoipClient, lookup: geoip_ip_data) }
    let(:geoip_ip_data) { instance_double(PhisherPhinder::GeoipIpData) }
    let(:ip_address_string) { '99.99.99.99' }

    subject { described_class.new(geoip_client: geoip_client) }

    it 'returns nil if the string is not an ip address' do
      expect(subject.build('mx.google.com')).to be_nil
    end

    it 'returns nil if passed nil as an argument' do
      expect(subject.build(nil)).to be_nil
    end

    describe 'when given a public ip address' do
      it 'fetches ip information from the geoip client' do
        expect(geoip_client).to receive(:lookup).with(ip_address_string)

        subject.build(ip_address_string)
      end

      it 'instantiates an extended ip instance' do
        ip = subject.build(ip_address_string)

        expect(ip).to eq(
          PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new(ip_address_string), geoip_ip_data: geoip_ip_data)
        )
      end
    end

    describe 'when given an IPV4 loopback address' do
      it 'does not fetch data from geoip' do
        expect(geoip_client).to_not receive(:lookup)

        subject.build('127.0.0.1')
        subject.build('127.255.255.255')
      end

      it 'returns a simple ip instance' do
        ip = subject.build('127.0.0.1')
        expect(ip).to eq(PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('127.0.0.1')))

        ip = subject.build('127.255.255.255')
        expect(ip).to eq(PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('127.255.255.255')))
      end
    end

    describe 'when given an IPV4 class A address' do
      it 'does not fetch data from geoip' do
        expect(geoip_client).to_not receive(:lookup)

        subject.build('10.0.0.1')
        subject.build('10.255.255.255')
      end

      it 'returns a simple ip instance' do
        ip = subject.build('10.0.0.1')
        expect(ip).to eq(PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('10.0.0.1')))

        ip = subject.build('10.255.255.255')
        expect(ip).to eq(PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('10.255.255.255')))
      end
    end

    describe 'when given an IPV4 class B address' do
      it 'does not fetch data from geoip' do
        expect(geoip_client).to_not receive(:lookup)

        subject.build('172.16.0.1')
        subject.build('172.31.255.255')
      end

      it 'returns a simple ip instance' do
        ip = subject.build('172.16.0.1')
        expect(ip).to eq(PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('172.16.0.1')))

        ip = subject.build('172.31.255.255')
        expect(ip).to eq(PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('172.31.255.255')))
      end
    end

    describe 'when given an IPV4 class C address' do
      it 'does not fetch data from geoip' do
        expect(geoip_client).to_not receive(:lookup)

        subject.build('192.168.0.0')
        subject.build('192.168.255.255')
      end

      it 'returns a simple ip instance' do
        ip = subject.build('192.168.0.1')
        expect(ip).to eq(PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('192.168.0.1')))

        ip = subject.build('192.168.255.255')
        expect(ip).to eq(PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('192.168.255.255')))
      end
    end

    describe 'when given an IPV6 loopback address' do
      it 'does not fetch data from geoip' do
        expect(geoip_client).to_not receive(:lookup)

        subject.build('::1/128')
      end

      it 'returns a simple ip instance' do
        ip = subject.build('::1/128')
        expect(ip).to eq(PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('::1/128')))
      end
    end

    describe 'when given an ip for which there is no geoip data' do
      it 'returns nil geoip data' do
        expect(geoip_client).to receive(:lookup).and_raise(MaxMind::GeoIP2::AddressNotFoundError)

        expect(subject.build('100.100.100.100')).to eq(
          PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('100.100.100.100'), geoip_ip_data: nil)
        )
      end
    end

    describe 'when given an ip that is a reserved address' do
      it 'returns nil geoip data' do
        expect(geoip_client).to receive(:lookup).and_raise(MaxMind::GeoIP2::AddressReservedError)

        expect(subject.build('100.100.100.100')).to eq(
          PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('100.100.100.100'), geoip_ip_data: nil)
        )
      end
    end

    describe 'when given a public IPV6 address' do
      it 'returns a simple ip instance' do
        expect(subject.build('2a00:d70:0:e::314')).to eq(
          PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('2a00:d70:0:e::314'))
        )
      end
    end
  end
end
