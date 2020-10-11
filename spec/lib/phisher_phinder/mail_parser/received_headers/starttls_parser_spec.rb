# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::ReceivedHeaders::StarttlsParser do
  let(:sample_1) { '(version=TLS1_2 cipher=ECDHE-ECDSA-AES128-GCM-SHA256 bits=128/128)' }
  let(:sample_2) do
    ' (using TLSv1.2 with cipher ECDHE-RSA-AES256-GCM-SHA384 (256/256 bits)) ' +
      '(No client certificate requested) '
  end
  let(:sample_3) do
    ' by host.test.zzz (10.10.10.10) with Microsoft SMTP Server ' +
      '(version=TLS1_2, cipher=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384) id 1.2.3.4 ' +
      'via Frontend Transport'
  end

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

  it 'sample_2' do
    expect(subject.parse(sample_2)).to eql({
      starttls: {
        version: 'TLSv1.2',
        cipher: 'ECDHE-RSA-AES256-GCM-SHA384',
        bits: '256/256'
      }
    })
  end

  it 'sample_3' do
    expect(subject.parse(sample_3)).to eql({
      starttls: {
        version: 'TLS1_2',
        cipher: 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
        bits: nil
      }
    })
  end
end
