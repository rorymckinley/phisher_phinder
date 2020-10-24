# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::ReceivedHeaders::ForParser do
  let(:sample_1) { 'for <dummy@test.com>' }
  let(:sample_2) { 'for dummy@test.com' }
  let(:sample_3) { 'for < dummy@test.com >' }
  let(:sample_4) do
    'for <dummy@test.com> (version=TLS1_2 cipher=ECDHE-ECDSA-AES128-GCM-SHA256 bits=128/128)'
  end
  let(:sample_5) do
    'for <dummy@test.com> (Google Transport Security)'
  end
  let(:starttls_parser) { PhisherPhinder::MailParser::ReceivedHeaders::StarttlsParser.new }

  subject { described_class.new(starttls_parser: starttls_parser) }

  it 'nil' do
    expect(subject.parse(nil)).to eql({recipient_mailbox: nil, starttls: nil})
  end

  it 'sample 1' do
    expect(subject.parse(sample_1)).to eql({recipient_mailbox: 'dummy@test.com', starttls: nil})
  end

  it 'sample 2' do
    expect(subject.parse(sample_2)).to eql({recipient_mailbox: 'dummy@test.com', starttls: nil})
  end

  it 'sample 3' do
    expect(subject.parse(sample_3)).to eql({recipient_mailbox: 'dummy@test.com', starttls: nil})
  end

  it 'sample 4' do
    expect(subject.parse(sample_4)).to eql(
      {
        recipient_mailbox: 'dummy@test.com',
        starttls: {
          version: 'TLS1_2',
          cipher: 'ECDHE-ECDSA-AES128-GCM-SHA256',
          bits: '128/128'
        }
      }
    )
  end

  it 'sample 5' do
    expect(subject.parse(sample_5)).to eql({recipient_mailbox: 'dummy@test.com', starttls: nil})
  end
end
