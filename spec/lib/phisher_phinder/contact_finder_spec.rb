# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::ContactFinder do
  let(:extended_ip) { PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('10.0.0.1'), geoip_ip_data: {}) }
  let(:simple_ip) { PhisherPhinder::SimpleIp.new(ip_address: IPAddr.new('10.0.0.2')) }
  let(:whois_client) { instance_double(Whois::Client) }
  let(:whois_email_extractor) { PhisherPhinder::WhoisEmailExtractor.new }

  subject { described_class.new(whois_client: whois_client, extractor: whois_email_extractor) }

  it 'returns an empty collection if the whois client raises a Whois::ServerNotFound error' do
    expect(whois_client).to receive(:lookup).and_raise(Whois::ServerNotFound)

    expect(subject.contacts_for(extended_ip)).to eql []
  end


  it 'returns an empty collection if passed a SimpleIp instance' do
    expect(subject.contacts_for(simple_ip)).to eql []
  end

  describe 'ExtendedIp instance' do
    let(:whois_content) do
      "OrgAbusePhone: +1-123-456-7890\n" +
        "OrgAbuseEmail: abuse@test.zzz\n" +
        "OrgAbuseRef: https://rdap.arin.net/registry/entity/XXXXXX"
    end
    let(:whois_record) { instance_double(Whois::Record, content: whois_content) }

    before(:each) do
      allow(whois_client).to receive(:lookup).and_return(whois_record)
    end

    it 'passes the ip address to the Whois client' do
      expect(whois_client).to receive(:lookup).with('10.0.0.1')

      subject.contacts_for(extended_ip)
    end

    it 'returns the email addresses extracted from the whois response' do
      expect(subject.contacts_for(extended_ip)).to eql ['abuse@test.zzz']
    end
  end

  describe 'host name' do
    let(:available_parser) { double(Whois::Parser, available?: true) }
    let(:broken_parser) do
      double(Whois::Parser).tap do |p|
        expect(p).to receive(:available?).and_raise(Whois::AttributeNotImplemented)
      end
    end
    let(:unavailable_parser) { double(Whois::Parser, available?: false) }
    let(:available_record) { instance_double(Whois::Record, parser: available_parser) }
    let(:broken_record) { instance_double(Whois::Record, parser: broken_parser) }
    let(:unavailable_record) { instance_double(Whois::Record, parser: unavailable_parser, content: whois_content) }
    let(:whois_content) do
      "Registrar Registration Expiration Date: 2021-09-27T19:29:52Z\n" +
        "Registrar: Foo\n" +
        "Registrar Abuse Contact Email: abuse@test.zzz\n" +
        "Registrar Abuse Contact Phone: +27.1234567\n" +
        "Reseller:\n" +
        "Domain Status: ok https://icann.org/epp#ok"
    end

    it 'attempts to find the most relevant whois data' do
      expect(whois_client).to receive(:lookup).with('foo.bar.baz.net').and_return(available_record)
      expect(whois_client).to receive(:lookup).with('bar.baz.net').and_return(available_record)
      expect(whois_client).to receive(:lookup).with('baz.net').and_return(unavailable_record)

      subject.contacts_for('foo.bar.baz.net')
    end

    it 'returns the email addresses extracted from the whois response' do
      allow(whois_client).to receive(:lookup).with('foo.bar.baz.net').and_return(available_record)
      allow(whois_client).to receive(:lookup).with('bar.baz.net').and_return(available_record)
      allow(whois_client).to receive(:lookup).with('baz.net').and_return(unavailable_record)

      expect(subject.contacts_for('foo.bar.baz.net')).to eql(['abuse@test.zzz'])
    end

    it 'returns an empty collection if the parser does nto implement the available attribute' do
      expect(whois_client).to receive(:lookup).with('foo.bar.baz.net').and_return(broken_record)

      expect(subject.contacts_for('foo.bar.baz.net')).to eql([])
    end
  end
end
