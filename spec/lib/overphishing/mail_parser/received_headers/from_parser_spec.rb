# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Overphishing::MailParser::ReceivedHeaders::FromParser do
  let(:enriched_ip_1) { instance_double(Overphishing::ExtendedIp) }
  let(:enriched_ip_2) { instance_double(Overphishing::ExtendedIp) }
  let(:enriched_ip_3) { instance_double(Overphishing::ExtendedIp) }
  let(:enriched_ip_4) { instance_double(Overphishing::ExtendedIp) }
  let(:enriched_ip_5) { instance_double(Overphishing::ExtendedIp) }
  let(:enriched_ip_6) { instance_double(Overphishing::ExtendedIp) }
  let(:enriched_ip_factory) do
    instance_double(Overphishing::ExtendedIpFactory).tap do |factory|
      allow(factory).to receive(:build) do |arg|
        case arg
        when '10.0.0.3'
          enriched_ip_1
        when '10.0.0.5'
          enriched_ip_2
        when '10.0.0.6'
          enriched_ip_3
        end
      end
    end
  end
  let(:sample_1) { 'from probably.not.real.com ([10.0.0.3])' }
  let(:sample_2) { 'from not.real.com (my.dodgy.host.com. [10.0.0.5])' }
  let(:sample_3) { '(from root@localhost)' }
  let(:sample_4) { 'from still.not.real.com (another.dodgy.host.com. 10.0.0.6)' }

  subject { described_class.new(enriched_ip_factory) }

  it 'nil input' do
    expect(subject.parse(nil)).to eql({
      advertised_sender: nil, sender: nil
    })
  end

  it 'sample 1' do
    expect(subject.parse(sample_1)).to eql({
      advertised_sender: 'probably.not.real.com',
      sender: {
        host: nil,
        ip: enriched_ip_1
      }
    })
  end

  it 'sample 2' do
    expect(subject.parse(sample_2)).to eql({
      advertised_sender: 'not.real.com',
      sender: {
        host: 'my.dodgy.host.com',
        ip: enriched_ip_2
      }
    })
  end

  it 'sample 3' do
    expect(subject.parse(sample_3)).to eql({
      advertised_sender: 'root@localhost',
      sender: {
        host: nil,
        ip: nil
      }
    })
  end

  it 'sample 4' do
    expect(subject.parse(sample_4)).to eql({
      advertised_sender: 'still.not.real.com',
      sender: {
        host: 'another.dodgy.host.com',
        ip: enriched_ip_3
      }
    })
  end
end
