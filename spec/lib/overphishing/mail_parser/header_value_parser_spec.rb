# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Overphishing::MailParser::HeaderValueParser do
  it 'strips off any padding' do
    expect(subject.parse(' foo  bar baz    ')).to eql 'foo  bar baz'
  end

  it 'parses a value that has UTF-8 Base64 encoding' do
    expect(subject.parse('=?UTF-8?b?Zm/DtQ==')).to eql 'foõ'
    expect(subject.parse('=?UTF-8?b?Zm/DtQ== =?UTF-8?b?w5/DpsOe =?UTF-8?b?Zm/EiQ==')).to eql 'foõßæÞfoĉ'
  end
end
