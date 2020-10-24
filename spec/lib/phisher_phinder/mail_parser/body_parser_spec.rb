# frozen_string_literal: true
require 'spec_helper'
require 'base64'

RSpec.describe PhisherPhinder::MailParser::BodyParser do
  let(:base64_transfer_encoding) { "base64" }
  let(:decoded_body) { "FooBar.\nBaz." }
  let(:encoded_body) { Base64.encode64(decoded_body) }
  let(:html_content_type) { "text/html; charset=UTF-8" }
  let(:line_end) { "\n" }
  let(:multipart_alternative_content_type) { 'multipart/alternative; boundary=boundary-foo-bar-baz' }
  let(:multipart_alternative_content_type_quoted) { 'multipart/alternative; boundary="boundary-foo-bar-baz' }
  let(:multipart_alternative_content_type_equals) { 'multipart/alternative; boundary="=boundary-foo-bar-baz' }
  let(:multipart_alternative_raw_body_1) { IO.read(File.join(FIXTURE_PATH, 'bodies', 'multipart_alternative.txt')) }
  let(:multipart_alternative_raw_body_2) { IO.read(File.join(FIXTURE_PATH, 'bodies', 'multipart_alternative_2.txt')) }
  let(:multipart_alternative_raw_body_3) { IO.read(File.join(FIXTURE_PATH, 'bodies', 'multipart_alternative_3.txt')) }
  let(:multipart_alternative_raw_body_4) { IO.read(File.join(FIXTURE_PATH, 'bodies', 'multipart_alternative_4.txt')) }
  let(:multipart_alternative_text_body) do
    "Unencoded Text" +
      "This is the first part of the text body.\nIt contains more than one line." +
      "This is the second part of the text body.\nIt contains more than one line."
  end
  let(:multipart_alternative_html_body_1) do
    "This is the first part of the HTML body.\nIt contains more than one line." +
      "This is the second part of the HTML body.\nIt contains more than one line."
  end

  let(:multipart_alternative_html_body_2) do
    "This is the first part of the HTML body.\nIt contains more than one line."
  end
  let(:text_body) { "this is the text body" }
  let(:text_content_type) { "text/plain; charset=UTF-8" }

  subject { described_class.new(line_end) }

  it 'returns the body as the text body if no content type is provided' do
    expect(
      subject.parse(body_contents: text_body, content_type: nil, content_transfer_encoding: nil)
    ).to eql({
      text: text_body,
      html: nil
    })
  end

  it 'returns the body as the text body if the content type is text' do
    expect(
      subject.parse( body_contents: text_body, content_type: text_content_type, content_transfer_encoding: nil)
    ).to eql({
      text: text_body,
      html: nil
    })
  end

  it 'returns the body as html if the content type is html' do
    expect(
      subject.parse(body_contents: decoded_body, content_type: html_content_type, content_transfer_encoding: nil)
    ).to eql({
      text: nil,
      html: decoded_body
    })
  end

  it 'returns a decoded html body if the body is encoded' do
    expect(
      subject.parse(
        body_contents: encoded_body,
        content_type: html_content_type,
        content_transfer_encoding: base64_transfer_encoding,
      )
    ).to eql({
      text: nil,
      html: decoded_body
    })
  end

  it 'can decode a multipart-alternative body' do
    expect(
      subject.parse(
        body_contents: multipart_alternative_raw_body_1,
        content_type: multipart_alternative_content_type,
        content_transfer_encoding: base64_transfer_encoding,
      )
    ).to eql({
      text: multipart_alternative_text_body,
      html: multipart_alternative_html_body_1,
    })
  end

  it 'can decode a multipart alternative body with a single block' do
    expect(
      subject.parse(
        body_contents: multipart_alternative_raw_body_2,
        content_type: multipart_alternative_content_type,
        content_transfer_encoding: base64_transfer_encoding,
      )
    ).to eql({
      text: '',
      html: multipart_alternative_html_body_2,
    })
  end

  it 'can decode a multipart-alternative body where the boundary is quoted' do
    expect(
      subject.parse(
        body_contents: multipart_alternative_raw_body_1,
        content_type: multipart_alternative_content_type_quoted,
        content_transfer_encoding: base64_transfer_encoding,
      )
    ).to eql({
      text: multipart_alternative_text_body,
      html: multipart_alternative_html_body_1,
    })
  end

  it 'can decode a multipart-alternative body where the boundary contains an =' do
    expect(
      subject.parse(
        body_contents: multipart_alternative_raw_body_3,
        content_type: multipart_alternative_content_type_equals,
        content_transfer_encoding: base64_transfer_encoding,
      )
    ).to eql({
      text: multipart_alternative_text_body,
      html: multipart_alternative_html_body_1,
    })
  end

  it 'can decode a multipart-alternative body that contains an empty block' do
    expect(
      subject.parse(
        body_contents: multipart_alternative_raw_body_1,
        content_type: multipart_alternative_content_type_quoted,
        content_transfer_encoding: base64_transfer_encoding,
      )
    ).to eql({
      text: multipart_alternative_text_body,
      html: multipart_alternative_html_body_1,
    })
  end
end
