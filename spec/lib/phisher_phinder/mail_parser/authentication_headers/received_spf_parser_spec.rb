# frozen_string_literal: true

RSpec.describe PhisherPhinder::MailParser::AuthenticationHeaders::ReceivedSpfParser do
  let(:enriched_ip_1) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_2) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_3) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_4) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:sample_1) do
    'pass (domain of test.zzz designates 10.0.0.3 as permitted sender)'
  end
  let(:sample_2) do
    'fail (host.zzz: domain of foo@test.zzz does not designate 10.0.0.5 as permitted sender) client-ip=10.0.0.6;'
  end
  let(:sample_3) do
    'neutral ' +
      '(host.zzz: 10.0.0.5 is neither permitted nor denied by best guess record for domain of foo@test.zzz) ' +
      'client-ip=10.0.0.6;'
  end
  let(:sample_4) do
    'softfail ' +
      '(host.zzz: domain of transitioning foo@test.zzz does not designate 10.0.0.5 as permitted sender) ' +
      'client-ip=10.0.0.6;'
  end
  let(:sample_5) do
    'Fail (host.zzz: domain of foo@test.zzz does not designate 10.0.0.5 as permitted sender) ' +
      'receiver=receiver.zzz; client-ip=10.0.0.6; ' +
      'helo=helo.zzz;'
  end
  let(:sample_6) do
    'Fail (host.zzz: domain of foo@test.zzz does not designate 10.0.0.5 as permitted sender) ' +
      'receiver=receiver.zzz; client-ip=10.0.0.6; ' +
      'helo=[10.0.0.7];'
  end
  let(:sample_7) do
    'softfail ' +
      '(host.zzz: transitioning domain of foo@test.zzz does not designate 10.0.0.5 as permitted sender) ' +
      'client-ip=10.0.0.6; envelope-from=foo2@test.zzz; ' +
      'helo=helo.zzz;'
  end
  let(:sample_8) do
    'none (domain of foo@test.zzz does not designate permitted sender hosts)'
  end
  let(:sample_9) do
    'Pass (mailfrom) identity=mailfrom; client-ip=10.0.0.5; ' +
    'helo=helo.zzz; envelope-from=foo2@test.zzz; receiver=<UNKNOWN>'
  end
  let(:sample_10) do
    'pass ' +
      '(host.zzz: best guess record for domain of foo@test.zzz designates 10.0.0.5 as permitted sender) ' +
      'client-ip=10.0.0.6;'
  end
  let(:extended_ip_factory) do
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
        when '2a00:d70:0:e::314'
          simple_ip_1
        end
      end
    end
  end

  subject { described_class.new(ip_factory: extended_ip_factory) }

  it 'sample_1' do
    expect(subject.parse(sample_1)).to eql({
      result: :pass,
      mailfrom: 'test.zzz',
      authserv_id: nil,
      ip: enriched_ip_1,
      client_ip: nil,
      helo: nil,
      receiver: nil,
      envelope_from: nil,
    })
  end

  it 'sample_2' do
    expect(subject.parse(sample_2)).to eql({
      result: :fail,
      mailfrom: 'foo@test.zzz',
      authserv_id: 'host.zzz',
      ip: enriched_ip_2,
      client_ip: enriched_ip_3,
      helo: nil,
      receiver: nil,
      envelope_from: nil,
    })
  end

  it 'sample 3' do
    expect(subject.parse(sample_3)).to eql({
      result: :neutral,
      mailfrom: 'foo@test.zzz',
      authserv_id: 'host.zzz',
      ip: enriched_ip_2,
      client_ip: enriched_ip_3,
      helo: nil,
      receiver: nil,
      envelope_from: nil,
    })
  end

  it 'sample 4' do
    expect(subject.parse(sample_4)).to eql({
      result: :softfail,
      mailfrom: 'foo@test.zzz',
      authserv_id: 'host.zzz',
      ip: enriched_ip_2,
      client_ip: enriched_ip_3,
      helo: nil,
      receiver: nil,
      envelope_from: nil,
    })
  end

  it 'sample 5' do
    expect(subject.parse(sample_5)).to eql({
      result: :fail,
      mailfrom: 'foo@test.zzz',
      authserv_id: 'host.zzz',
      ip: enriched_ip_2,
      client_ip: enriched_ip_3,
      helo: 'helo.zzz',
      receiver: 'receiver.zzz',
      envelope_from: nil,
    })
  end

  it 'sample 6' do
    expect(subject.parse(sample_6)).to eql({
      result: :fail,
      mailfrom: 'foo@test.zzz',
      authserv_id: 'host.zzz',
      ip: enriched_ip_2,
      client_ip: enriched_ip_3,
      helo: enriched_ip_4,
      receiver: 'receiver.zzz',
      envelope_from: nil,
    })
  end

  it 'sample 7' do
    expect(subject.parse(sample_7)).to eql({
      result: :softfail,
      mailfrom: 'foo@test.zzz',
      authserv_id: 'host.zzz',
      ip: enriched_ip_2,
      client_ip: enriched_ip_3,
      helo: 'helo.zzz',
      receiver: nil,
      envelope_from: 'foo2@test.zzz',
    })
  end

  it 'sample 8' do
    expect(subject.parse(sample_8)).to eql({
      result: :none,
      mailfrom: 'foo@test.zzz',
      authserv_id: nil,
      ip: nil,
      client_ip:  nil,
      helo: nil,
      receiver: nil,
      envelope_from: nil,
    })
  end

  it 'sample 9' do
    expect(subject.parse(sample_9)).to eql({
      result: :pass,
      mailfrom: nil,
      authserv_id: nil,
      ip: nil,
      client_ip: enriched_ip_2,
      helo: 'helo.zzz',
      receiver: '<UNKNOWN>',
      envelope_from: 'foo2@test.zzz',
    })
  end

  it 'sample 10' do
    expect(subject.parse(sample_10)).to eql({
      result: :pass,
      mailfrom: 'foo@test.zzz',
      authserv_id: 'host.zzz',
      ip: enriched_ip_2,
      client_ip: enriched_ip_3,
      helo: nil,
      receiver: nil,
      envelope_from: nil,
    })
  end
end
