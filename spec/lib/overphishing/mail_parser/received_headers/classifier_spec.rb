# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Overphishing::MailParser::ReceivedHeaders::Classifier  do
  let(:complete_tls) do
    {
      advertised_sender: 'x', recipient_mailbox: 'y', recipient: 'z', protocol: 'ESMTPS', starttls: {}
    }
  end
  let(:complete_no_tls_1) do
    {
      advertised_sender: 'x', recipient_mailbox: 'y', recipient: 'z'
    }
  end
  let(:complete_no_tls_2) do
    {
      advertised_sender: 'x', recipient_mailbox: 'y', recipient: 'z', protocol: 'ESMTP'
    }
  end
  let(:incomplete_no_advertised_sender) do
    {
      recipient_mailbox: 'y', recipient: 'z'
    }
  end
  let(:incomplete_esmtps_no_starttls) do
    {
      advertised_sender: 'x', recipient_mailbox: 'y', recipient: 'z', protocol: 'ESMTPS'
    }
  end
  let(:incomplete_no_recipient) do
    {
      advertised_sender: 'x', recipient_mailbox: 'y'
    }
  end
  let(:incomplete_no_recipient_mailbox) do
    {
      advertised_sender: 'x', recipient: 'z'
    }
  end
  let(:incomplete_starttls_no_esmtps) do
    {
      advertised_sender: 'x', recipient_mailbox: 'y', recipient: 'z', starttls: {}
    }
  end

  it 'complete tls' do
    expect(subject.classify(complete_tls)).to eql({partial: false})
  end

  it 'incomplete TLS' do
    expect(subject.classify(complete_no_tls_1)).to eql({partial: false})
    expect(subject.classify(complete_no_tls_2)).to eql({partial: false})
  end

  it 'incomplete no advertised sender' do
    expect(subject.classify(incomplete_no_advertised_sender)).to eql({partial: true})
  end

  it 'incomplete no recipient' do
    expect(subject.classify(incomplete_no_recipient)).to eql({partial: true})
  end

  it 'incomplete no recipient mailbox' do
    expect(subject.classify(incomplete_no_recipient_mailbox)).to eql({partial: true})
  end

  it 'incomplete ESMTPS but no starttls' do
    expect(subject.classify(incomplete_esmtps_no_starttls)).to eql({partial: true})
  end

  it 'incomplete starttls but no ESMTPS' do
    expect(subject.classify(incomplete_starttls_no_esmtps)).to eql({partial: true})
  end
end
