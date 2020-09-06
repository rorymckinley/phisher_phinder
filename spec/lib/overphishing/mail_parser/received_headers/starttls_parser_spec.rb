# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Overphishing::MailParser::ReceivedHeaders::StarttlsParser do
  let(:sample_1) { '(version=TLS1_2 cipher=ECDHE-ECDSA-AES128-GCM-SHA256 bits=128/128)' }

  it 'nil' do
    expect(subject.parse(nil)).to eql({starttls: nil})
  end

  it 'sample_1' do
    expect(subject.parse(sample_1)).to eql({
      starttls: {
        version: 'TLS1_2',
        cipher: 'ECDHE-ECDSA-AES128-GCM-SHA256',
        bits: '128/128'
      }
    })
  end
end
