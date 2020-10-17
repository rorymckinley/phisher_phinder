# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::ReceivedHeaders::ForParser do
  let(:sample_1) { 'for <dummy@test.com>' }
  let(:sample_2) { 'for dummy@test.com' }
  let(:sample_3) { 'for < dummy@test.com >' }

  it 'nil' do
    expect(subject.parse(nil)).to eql({recipient_mailbox: nil})
  end

  it 'sample 1' do
    expect(subject.parse(sample_1)).to eql({recipient_mailbox: 'dummy@test.com'})
  end

  it 'sample 2' do
    expect(subject.parse(sample_2)).to eql({recipient_mailbox: 'dummy@test.com'})
  end

  it 'sample 3' do
    expect(subject.parse(sample_3)).to eql({recipient_mailbox: 'dummy@test.com'})
  end
end
