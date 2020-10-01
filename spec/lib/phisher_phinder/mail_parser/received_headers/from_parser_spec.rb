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

  subject { described_class.new(enriched_ip_factory) }

  it 'nil input' do
    expect(subject.parse(nil)).to eql({
      advertised_sender: nil, helo: nil, sender: nil
    })
  end

  it 'sample 1' do
    expect(subject.parse(sample_1)).to eql({
      advertised_sender: 'probably.not.real.com',
      helo: nil,
      sender: {
        host: nil,
        ip: enriched_ip_1
      }
    })
  end

  it 'sample 2' do
    expect(subject.parse(sample_2)).to eql({
      advertised_sender: 'not.real.com',
      helo: nil,
      sender: {
        host: 'my.dodgy.host.com',
        ip: enriched_ip_2
      }
    })
  end

  it 'sample 3' do
    expect(subject.parse(sample_3)).to eql({
      advertised_sender: 'root@localhost',
      helo: nil,
      sender: {
        host: nil,
        ip: nil
      }
    })
  end

  it 'sample 4' do
    expect(subject.parse(sample_4)).to eql({
      advertised_sender: 'still.not.real.com',
      helo: nil,
      sender: {
        host: 'another.dodgy.host.com',
        ip: enriched_ip_3
      }
    })
  end

  it 'sample 5' do
    expect(subject.parse(sample_5)).to eql({
      advertised_sender: 'not.real.com',
      helo: nil,
      sender: {
        host: nil,
        ip: enriched_ip_4
      }
    })
  end

  it 'sample 6' do
    expect(subject.parse(sample_6)).to eql({
      advertised_sender: 'root',
      helo: nil,
      sender: {
        host: nil,
        ip: nil
      }
    })
  end

  it 'sample 7' do
    expect(subject.parse(sample_7)).to eql({
      advertised_sender: 'probably.not.real',
      helo: 'foo',
      sender: {
        host: nil,
        ip: enriched_ip_1
      }
    })
  end

  it 'sample 8' do
    expect(subject.parse(sample_8)).to eql({
      advertised_sender: 'probably.not.real',
      helo: 'foo',
      sender: {
        host: nil,
        ip: nil
      }
    })
  end
end
