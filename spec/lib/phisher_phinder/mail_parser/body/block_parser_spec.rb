# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::Body::BlockParser do
  let(:base64_windows_1251) do
    {
      content_type: :not_relevant,
      character_set: :windows_1251,
      content_transfer_encoding: :base64,
      content: '0OXq6+Ds4CDt5SDk4OXyIPDl5/Pr/PLg8j8=?='
    }
  end
  let(:base64_utf8) do
    {
      content_type: :not_relevant,
      character_set: :utf_8,
      content_transfer_encoding: :base64,
      content: 'Zm/DtcOfw6bDnmZvxIk='
    }
  end
  let(:nil_utf_8) do
    {
      content_type: :not_relevant,
      character_set: :utf_8,
      content_transfer_encoding: nil,
      content: 'foõßæÞfoĉ'
    }
  end
  let(:parsed_utf8) { 'foõßæÞfoĉ' }
  let(:parsed_windows_1251) { 'Реклама не дает результат?' }
  let(:quoted_printable_utf8) do
    {
      content_type: :not_relevant,
      character_set: :utf_8,
      content_transfer_encoding: :quoted_printable,
      content: "fo=C3=B5=C3=9F=C3=A6=C3=9Efo=C4=89=\n"
    }
  end
  let(:seven_bit_utf_8) do
    {
      content_type: :not_relevant,
      character_set: :utf_8,
      content_transfer_encoding: :seven_bit,
      content: 'foõßæÞfoĉ'
    }
  end

  it 'correctly parses the content', :aggregate_failures do
    expect(subject.parse(base64_windows_1251)).to eql parsed_windows_1251
    expect(subject.parse(base64_utf8)).to eql parsed_utf8
    expect(subject.parse(quoted_printable_utf8)).to eql parsed_utf8
    expect(subject.parse(seven_bit_utf_8)).to eql parsed_utf8
    expect(subject.parse(nil_utf_8)).to eql parsed_utf8
  end
end
