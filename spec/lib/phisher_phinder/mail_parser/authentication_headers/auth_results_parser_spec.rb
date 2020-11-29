# frozen_string_literal: true

RSpec.describe PhisherPhinder::MailParser::AuthenticationHeaders::AuthResultsParser do
  let(:enriched_ip_1) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_2) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_3) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_4) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:simple_ip_1) { instance_double(PhisherPhinder::SimpleIp) }
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
        when '2a00:d70:0:e::314'
          simple_ip_1
        end
      end
    end
  end

  let(:sample_1) do
    [
      'mail.test.zzz; ',
      'dkim=temperror (no key for signature) header.i=@test.com header.s=default header.b=hFTcwQo7; ',
      'spf=neutral (mail.test.zzz: 10.0.0.3 is neither permitted nor denied by best guess record for domain of ',
      'foo@test.com) smtp.mailfrom=foo@test.com'
    ].join
  end
  let(:sample_2) do
    [
      'mail.test.zzz; ',
      'spf=pass (mail.test.zzz: domain of foo@test.com designates 10.0.0.3 as permitted sender) ',
      'smtp.mailfrom=foo@test.com; ',
      'dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=test.com'
    ].join
  end
  let(:sample_3) do
    [
      'mail.test.zzz; ',
      'spf=fail (mail.test.zzz: domain of foo@test.com does not designate 10.0.0.3 as permitted sender) ',
      'smtp.mailfrom=foo@test.com; ',
      'dmarc=pass (p=NONE sp=NONE dis=NONE) header.from=test.com'
    ].join
  end
  let(:sample_4) do
    [
      'mail.test.zzz; ',
      'dkim=pass header.i=@test.com header.s=default header.b=hFTcwQo7;',
      'spf=neutral (mail.test.zzz: 10.0.0.3 is neither permitted nor denied by best guess record for domain of ',
      'foo@test.com) smtp.mailfrom=foo@test.com'
    ].join
  end
  let(:sample_5) do
    [
      'mail.test.zzz; ',
      'dkim=neutral (body hash did not verify) header.i=@test.com header.s=default header.b=hFTcwQo7;',
      'spf=neutral (mail.test.zzz: 10.0.0.3 is neither permitted nor denied by best guess record for domain of ',
      'foo@test.com) smtp.mailfrom=foo@test.com'
    ].join
  end
  let(:sample_6) do
    [
      'mail.test.zzz; ',
      'iprev=pass (sender.foo.bar) smtp.remote-ip=10.0.0.5; ',
      'spf=neutral smtp.mailfrom=foo@test.com'
    ].join
  end
  let(:sample_7) do
    [
      'host-h.net; ',
      'auth=pass (login) smtp.auth=@test.com'
    ].join
  end
  let(:sample_8) do
    [
      'mail.test.zzz; ',
      'spf=neutral (mail.test.zzz: 2a00:d70:0:e::314 is neither permitted nor denied by best guess record for domain ',
      'of foo@test.com) smtp.mailfrom=foo@test.com'
    ].join
  end

  subject { described_class.new(ip_factory: enriched_ip_factory) }

  it 'sample 1' do
    expect(subject.parse(sample_1)).to eql({
      authserv_id: 'mail.test.zzz',
      dkim: {
        result: :temperror,
        identity: '@test.com',
        selector: 'default',
        hash_snippet: 'hFTcwQo7'
      },
      spf: {
        result: :neutral,
        ip: enriched_ip_1,
        from: 'foo@test.com'
      },
    })
  end

  it 'sample 2 - SPF' do
    expect(subject.parse(sample_2)).to eql({
      authserv_id: 'mail.test.zzz',
      spf: {
        result: :pass,
        ip: enriched_ip_1,
        from: 'foo@test.com'
      },
    })
  end

  it 'sample 3' do
    expect(subject.parse(sample_3)).to eql({
      authserv_id: 'mail.test.zzz',
      spf: {
        result: :fail,
        ip: enriched_ip_1,
        from: 'foo@test.com'
      },
    })
  end

  it 'sample 4 - dkim' do
    expect(subject.parse(sample_4)[:dkim]).to eql({
      result: :pass,
      identity: '@test.com',
      selector: 'default',
      hash_snippet: 'hFTcwQo7',
    })
  end

  it 'sample 5 - dkim' do
    expect(subject.parse(sample_5)[:dkim]).to eql({
      result: :neutral,
      identity: '@test.com',
      selector: 'default',
      hash_snippet: 'hFTcwQo7',
    })
  end

  it 'sample 6 - iprev' do
    expect(subject.parse(sample_6)[:iprev]).to eql({
      result: :pass,
      remote_host_name: 'sender.foo.bar',
      remote_ip: enriched_ip_2
    })
  end

  it 'sample 6 - spf' do
    expect(subject.parse(sample_6)[:spf]).to eql({
      result: :neutral,
      ip: nil,
      from: 'foo@test.com'
    })
  end

  it 'sample 7 - auth' do
    expect(subject.parse(sample_7)[:auth]).to eql({
      result: :pass,
      domain: '@test.com'
    })
  end

  it 'sample 8 - spf' do
    expect(subject.parse(sample_8)).to eql({
      authserv_id: 'mail.test.zzz',
      spf: {
        result: :neutral,
        ip: simple_ip_1,
        from: 'foo@test.com'
      },
    })

  end
end
