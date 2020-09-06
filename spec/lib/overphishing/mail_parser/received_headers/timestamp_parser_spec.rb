# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Overphishing::MailParser::ReceivedHeaders::TimestampParser do
  let(:sample_1) { 'Sat, 25 Apr 2020 22:14:04 -0700 (PDT)' }
  let(:sample_2) { 'Sat, 25 Apr 2020 22:14:05 -0700' }

  it 'nil' do
    expect(subject.parse(nil)).to eql({time: nil})
  end

  it 'sample 1' do
    expect(subject.parse(sample_1)).to eql({time: Time.new(2020, 4, 25, 22, 14, 4, "-07:00")})
  end

  it 'sample 2' do
    expect(subject.parse(sample_2)).to eql({time: Time.new(2020, 4, 25, 22, 14, 5, "-07:00")})
  end
end
