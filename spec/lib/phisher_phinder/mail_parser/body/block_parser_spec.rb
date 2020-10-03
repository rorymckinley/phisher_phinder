# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::Body::BlockParser do
  let(:base64_windows_1251) do
    {
      content_type: :not_relevant,
      character_set: :windows_1251,
      content_transfer_encoding: :base64,
      content: "0OXq6+Ds4CDt5SD\nk4OXyIPDl5/Pr/PLg8j8=?="
    }
  end
  let(:base64_utf8) do
    {
      content_type: :not_relevant,
      character_set: :utf_8,
      content_transfer_encoding: :base64,
      content: "Zm/DtcOfw\n6bDnmZvxIk="
    }
  end
  let(:line_end) { "\n" }
  let(:nil_utf_8) do
    {
      content_type: :not_relevant,
      character_set: :utf_8,
      content_transfer_encoding: nil,
      content: "foõßæÞfoĉ"
    }
  end
  let(:parsed_utf8) { "foõßæÞfoĉ" }
  let(:parsed_utf8_with_line_break) { "foõ\nßæÞfoĉ" }
  let(:parsed_utf8_2) { 'foõ=B_ßæÞ=Nfoĉ' }
  let(:parsed_windows_1251) { 'Реклама не дает результат?' }
  let(:quoted_printable_utf8) do
    {
      content_type: :not_relevant,
      character_set: :utf_8,
      content_transfer_encoding: :quoted_printable,
      content: "fo=C3=B5=\n=C3=9F=C3=A6=C3=9Efo=C4=89=\n"
    }
  end
  let(:broken_quoted_printable_utf8) do
    {
      content_type: :not_relevant,
      character_set: :utf_8,
      content_transfer_encoding: :quoted_printable,
      content: "fo=C3=B5=B_=C3=9F=C3=A6=C3=9E=Nfo=C4=89=\n"
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

  subject { described_class.new(line_end) }

  it 'correctly parses the content' do
    expect(subject.parse(base64_windows_1251)).to eql parsed_windows_1251
    expect(subject.parse(base64_utf8)).to eql parsed_utf8
    expect(subject.parse(quoted_printable_utf8)).to eql parsed_utf8
    expect(subject.parse(broken_quoted_printable_utf8)).to eql parsed_utf8_2
    expect(subject.parse(seven_bit_utf_8)).to eql parsed_utf8
    expect(subject.parse(nil_utf_8)).to eql parsed_utf8
  end
end
