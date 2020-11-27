# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::ReceivedHeaders::FromParser do
  let(:enriched_ip_1) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_2) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_3) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_4) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_factory) do
    instance_double(PhisherPhinder::ExtendedIpFactory).tap do |factory|
      allow(factory).to receive(:build) do |arg|
        case arg
        when '10.0.0.3'
          enriched_ip_1
        when '10.0.0.5'
          enriched_ip_2
        when '10.0.0.6'
          enriched_ip_3
        when '10.0.0.7'
          enriched_ip_4
        end
      end
    end
  end
  let(:sample_1) { 'from probably.not.real.com ([10.0.0.3])' }
  let(:sample_2) { 'from not.real.com (my.dodgy.host.com. [10.0.0.5])' }
  let(:sample_3) { '(from root@localhost)' }
  let(:sample_4) { 'from still.not.real.com (another.dodgy.host.com. 10.0.0.6)' }
  let(:sample_5) { 'from not.real.com (10.0.0.7)' }
  let(:sample_6) { 'from root ' }
  let(:sample_7) { 'from probably.not.real (HELO foo) ([10.0.0.3])' }
  let(:sample_8) { 'from probably.not.real (HELO foo) () ' }
  let(:sample_9) do
    'from probably.not.real (unknown [10.0.0.3]) (using TLSv1.2 with cipher ECDHE-RSA-AES256-GCM-SHA384 (256/256 bits))'
  end
  let(:sample_10) do
    'from [10.0.0.3] (unknown [10.0.0.3]) (Authenticated sender: foo-bar)'
  end
  let(:starttls_parser) { PhisherPhinder::MailParser::ReceivedHeaders::StarttlsParser.new }

  subject { described_class.new(ip_factory: enriched_ip_factory, starttls_parser: starttls_parser) }

  it 'nil input' do
    expect(subject.parse(nil)).to eql({
      advertised_authenticated_sender: nil, advertised_sender: nil, helo: nil, sender: nil, starttls: nil
    })
  end

  it 'sample 1' do
    expect(subject.parse(sample_1)).to eql({
      advertised_authenticated_sender: nil,
      advertised_sender: 'probably.not.real.com',
      helo: nil,
      sender: {
        host: nil,
        ip: enriched_ip_1
      },
      starttls: nil
    })
  end

  it 'sample 2' do
    expect(subject.parse(sample_2)).to eql({
      advertised_authenticated_sender: nil,
      advertised_sender: 'not.real.com',
      helo: nil,
      sender: {
        host: 'my.dodgy.host.com',
        ip: enriched_ip_2
      },
      starttls: nil
    })
  end

  it 'sample 3' do
    expect(subject.parse(sample_3)).to eql({
      advertised_authenticated_sender: nil,
      advertised_sender: 'root@localhost',
      helo: nil,
      sender: {
        host: nil,
        ip: nil
      },
      starttls: nil
    })
  end

  it 'sample 4' do
    expect(subject.parse(sample_4)).to eql({
      advertised_authenticated_sender: nil,
      advertised_sender: 'still.not.real.com',
      helo: nil,
      sender: {
        host: 'another.dodgy.host.com',
        ip: enriched_ip_3
      },
      starttls: nil
    })
  end

  it 'sample 5' do
    expect(subject.parse(sample_5)).to eql({
      advertised_authenticated_sender: nil,
      advertised_sender: 'not.real.com',
      helo: nil,
      sender: {
        host: nil,
        ip: enriched_ip_4
      },
      starttls: nil
    })
  end

  it 'sample 6' do
    expect(subject.parse(sample_6)).to eql({
      advertised_authenticated_sender: nil,
      advertised_sender: 'root',
      helo: nil,
      sender: {
        host: nil,
        ip: nil
      },
      starttls: nil
    })
  end

  it 'sample 7' do
    expect(subject.parse(sample_7)).to eql({
      advertised_authenticated_sender: nil,
      advertised_sender: 'probably.not.real',
      helo: 'foo',
      sender: {
        host: nil,
        ip: enriched_ip_1
      },
      starttls: nil
    })
  end

  it 'sample 8' do
    expect(subject.parse(sample_8)).to eql({
      advertised_authenticated_sender: nil,
      advertised_sender: 'probably.not.real',
      helo: 'foo',
      sender: {
        host: nil,
        ip: nil
      },
      starttls: nil
    })
  end

  it 'sample 9' do
    expect(subject.parse(sample_9)).to eql({
      advertised_authenticated_sender: nil,
      advertised_sender: 'probably.not.real',
      helo: nil,
      sender: {
        host: 'unknown',
        ip: enriched_ip_1
      },
      starttls: {
        version: 'TLSv1.2',
        cipher: 'ECDHE-RSA-AES256-GCM-SHA384',
        bits: '256/256'
      }
    })
  end

  it 'sample_10' do
    expect(subject.parse(sample_10)).to eql({
      advertised_authenticated_sender: 'foo-bar',
      advertised_sender: enriched_ip_1,
      helo: nil,
      sender: {
        host: 'unknown',
        ip: enriched_ip_1
      },
      starttls: nil
    })
  end
end
