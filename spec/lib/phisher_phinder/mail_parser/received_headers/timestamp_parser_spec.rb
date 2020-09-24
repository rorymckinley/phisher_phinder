# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::ReceivedHeaders::TimestampParser do
  let(:sample_1) { 'Sat, 25 Apr 2020 22:14:04 -0700 (PDT)' }
  let(:sample_1_padded) { ' Sat, 25 Apr 2020 22:14:04 -0700 (PDT) ' }
  let(:sample_2) { 'Sat, 25 Apr 2020 22:14:05 -0700' }
  let(:sample_2_padded) { ' Sat, 25 Apr 2020 22:14:05 -0700 ' }
  let(:sample_3) { '10 Sep 2020 08:55:25 +1000' }
  let(:sample_3_padded) { ' 10 Sep 2020 08:55:25 +1000 ' }

  it 'nil' do
    expect(subject.parse(nil)).to eql({time: nil})
  end

  it 'sample 1' do
    expect(subject.parse(sample_1)).to eql({time: Time.new(2020, 4, 25, 22, 14, 4, "-07:00")})
    expect(subject.parse(sample_1_padded)).to eql({time: Time.new(2020, 4, 25, 22, 14, 4, "-07:00")})
  end

  it 'sample 2' do
    expect(subject.parse(sample_2)).to eql({time: Time.new(2020, 4, 25, 22, 14, 5, "-07:00")})
    expect(subject.parse(sample_2_padded)).to eql({time: Time.new(2020, 4, 25, 22, 14, 5, "-07:00")})
  end

  it 'sample 3' do
    expect(subject.parse(sample_3)).to eql({time: Time.new(2020, 9, 10, 8, 55, 25, "+10:00")})
    expect(subject.parse(sample_3_padded)).to eql({time: Time.new(2020, 9, 10, 8, 55, 25, "+10:00")})
  end

  it 'raises an error if the available patterns do not match the timestamp' do
    expect { subject.parse('foo bar baz') }.to raise_error "Could not match `foo bar baz` with the available patterns"
  end
end
