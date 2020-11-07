# frozen_string_literal: true

RSpec.describe PhisherPhinder::MailParser::AuthenticationHeaders::AuthResultsParser do
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

  subject { described_class.new(ip_factory: enriched_ip_factory) }

  it 'sample 1' do
    expect(subject.parse(sample_1)).to eql({
      authserv_id: 'mail.test.zzz',
      spf: {
        result: :neutral,
        ip: enriched_ip_1,
        from: 'foo@test.com'
      },
    })
  end

  it 'sample 2' do
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
end
