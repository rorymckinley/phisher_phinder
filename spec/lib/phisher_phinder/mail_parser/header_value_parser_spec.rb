# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::HeaderValueParser do
  it 'strips off any padding' do
    expect(subject.parse(' foo  bar baz    ')).to eql 'foo  bar baz'
  end

  it 'parses a value that has UTF-8 Base64 encoding' do
    expect(subject.parse('  =?UTF-8?b?Zm/DtQ==  ')).to eql 'foõ'
    expect(subject.parse('=?UTF-8?b?Zm/DtQ== =?UTF-8?b?w5/DpsOe =?UTF-8?b?Zm/EiQ==')).to eql 'foõßæÞfoĉ'
  end

  it 'parses a value that has Windows-1251 Base64 encoding' do
    expect(
      subject.parse('=?windows-1251?B?0OXq6+Ds4CDt5SDk4OXyIPDl5/Pr/PLg8j8=?= =?windows-1251?B?Zm9vIGJhcg==')
    ).to eql('Реклама не дает результат?foo bar')
  end
end
