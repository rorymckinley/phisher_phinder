# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::MailParser::Body::BlockClassifier do
  describe 'classify_block' do
    let(:html_iso_8859_base_64_1) do
      "Content-Type: text/html; charset=\"iso-8859-1\"\n" +
        "Content-Transfer-Encoding: base64\n" +
        "\n" +
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj\n" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu\n"
    end
    let(:html_iso_8859_base_64_2) do
      "Content-Type: text/html; charset=\"ISO-8859-1\"\n" +
        "Content-Transfer-Encoding: base64\n" +
        "\n" +
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj\n" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu\n"
    end
    let(:html_utf_8_7bit) do
      "Content-Type: text/html; charset=\"UTF-8\"\n" +
        "Content-Transfer-Encoding: 7bit\n" +
        "\n" +
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj\n" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu\n"
    end
    let(:html_utf_8_base64_1) do
      "Content-Type: text/html; charset=\"UTF-8\"\n" +
        "Content-Transfer-Encoding: base64\n" +
        "\n" +
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj\n" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu\n"
    end
    let(:html_utf_8_base64_2) do
      "Content-Type: text/html; charset=utf-8\n" +
        "Content-Transfer-Encoding: base64\n" +
        "\n" +
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj\n" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu\n"
    end
    let(:html_utf_8_quoted_printable) do
      "Content-Type: text/html; charset=\"UTF-8\"\n" +
        "Content-Transfer-Encoding: quoted-printable\n" +
        "\n" +
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj\n" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu\n"
    end
    let(:html_windows_1251_base_64_1) do
      "Content-Type: text/html; charset=\"windows-1251\"\n" +
        "Content-Transfer-Encoding: base64\n" +
        "\n" +
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj\n" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu\n"
    end
    let(:html_windows_1251_base_64_2) do
      "Content-Type: text/html; charset=\"WINDOWS-1251\"\n" +
        "Content-Transfer-Encoding: base64\n" +
        "\n" +
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj\n" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu\n"
    end
    let(:no_headers) do
      "\nFooBarBaz\n"
    end
    let(:text_utf_8_base64) do
      "Content-Type: text/plain; charset=utf-8\n" +
        "Content-Transfer-Encoding: base64\n" +
        "\n" +
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj\n" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu\n"
    end

    subject { described_class.new("\n") }

    it 'correctly classifies the content type of a block' do
      expect(subject.classify_block(text_utf_8_base64)[:content_type]).to eql :text
      expect(subject.classify_block(html_utf_8_base64_1)[:content_type]).to eql :html
      expect(subject.classify_block(no_headers)[:content_type]).to eql :text
    end

    it 'correctly classifies the character set' do
      expect(subject.classify_block(text_utf_8_base64)[:character_set]).to eql :utf_8
      expect(subject.classify_block(html_utf_8_base64_1)[:character_set]).to eql :utf_8
      expect(subject.classify_block(html_iso_8859_base_64_1)[:character_set]).to eql :iso_8859_1
      expect(subject.classify_block(html_iso_8859_base_64_2)[:character_set]).to eql :iso_8859_1
      expect(subject.classify_block(html_windows_1251_base_64_1)[:character_set]).to eql :windows_1251
      expect(subject.classify_block(html_windows_1251_base_64_2)[:character_set]).to eql :windows_1251
      expect(subject.classify_block(no_headers)[:character_set]).to eql :utf_8
    end

    it 'correctly classifies the encoding' do
      expect(subject.classify_block(text_utf_8_base64)[:content_transfer_encoding]).to eql :base64
      expect(subject.classify_block(html_utf_8_7bit)[:content_transfer_encoding]).to eql :seven_bit
      expect(subject.classify_block(html_utf_8_quoted_printable)[:content_transfer_encoding]).to eql :quoted_printable
      expect(subject.classify_block(no_headers)[:content_transfer_encoding]).to be_nil
    end

    it 'returns the content for the block' do
      expect(subject.classify_block(text_utf_8_base64)[:content]).to eql(
        "VGhpcyBpcyB0aGUgZmlyc3QgcGFydCBvZiB0aGUgdGV4dCBib2R5LgpJdCBj" +
        "b250YWlucyBtb3JlIHRoYW4gb25lIGxpbmUu"
      )
      expect(subject.classify_block(no_headers)[:content]).to eql 'FooBarBaz'
    end
  end

  describe 'classify_headers' do
    let(:html_iso_8859_base_64_1) do
      {
        content_type: 'text/html; charset="iso-8859-1"',
        content_transfer_encoding: 'base64'
      }
    end
    let(:html_iso_8859_base_64_2) do
      {
        content_type: 'text/html; charset="ISO-8859-1"',
        content_transfer_encoding: 'base64'
      }
    end
    let(:html_utf_8_7bit) do
      {
        content_type: 'text/html; charset="UTF-8"',
        content_transfer_encoding: '7bit'
      }
    end
    let(:html_utf_8_base64_1) do
      {
        content_type: 'text/html; charset="utf-8"',
        content_transfer_encoding: 'base64'
      }
    end
    let(:html_utf_8_base64_2) do
      {
        content_type: 'text/html; charset=UTF-8',
        content_transfer_encoding: 'base64'
      }
    end
    let(:html_utf_8_quoted_printable) do
      {
        content_type: 'text/html; charset="UTF-8"',
        content_transfer_encoding: 'quoted-printable'
      }
    end
    let(:html_windows_1251_base_64_1) do
      {
        content_type: 'text/html; charset="windows-1251',
        content_transfer_encoding: 'base64'
      }
    end
    let(:html_windows_1251_base_64_2) do
      {
        content_type: 'text/html; charset="WINDOWS-1251',
        content_transfer_encoding: 'base64'
      }
    end
    let(:no_headers) do
      {}
    end
    let(:text_utf_8_base64) do
      {
        content_type: 'text/plain; charset="UTF-8"',
        content_transfer_encoding: 'base64'
      }
    end

    subject { described_class.new("\n") }

    it 'correctly classifies the content type of a block' do
      expect(subject.classify_headers(text_utf_8_base64)[:content_type]).to eql :text
      expect(subject.classify_headers(html_utf_8_base64_1)[:content_type]).to eql :html
      expect(subject.classify_headers(no_headers)[:content_type]).to eql :text
    end

    it 'correctly classifies the character set' do
      expect(subject.classify_headers(text_utf_8_base64)[:character_set]).to eql :utf_8
      expect(subject.classify_headers(html_utf_8_base64_1)[:character_set]).to eql :utf_8
      expect(subject.classify_headers(html_iso_8859_base_64_1)[:character_set]).to eql :iso_8859_1
      expect(subject.classify_headers(html_iso_8859_base_64_2)[:character_set]).to eql :iso_8859_1
      expect(subject.classify_headers(html_windows_1251_base_64_1)[:character_set]).to eql :windows_1251
      expect(subject.classify_headers(html_windows_1251_base_64_2)[:character_set]).to eql :windows_1251
      expect(subject.classify_headers(no_headers)[:character_set]).to eql :utf_8
    end

    it 'correctly classifies the encoding' do
      expect(subject.classify_headers(text_utf_8_base64)[:content_transfer_encoding]).to eql :base64
      expect(subject.classify_headers(html_utf_8_7bit)[:content_transfer_encoding]).to eql :seven_bit
      expect(subject.classify_headers(html_utf_8_quoted_printable)[:content_transfer_encoding]).to eql :quoted_printable
      expect(subject.classify_headers(no_headers)[:content_transfer_encoding]).to be_nil
    end
  end
end
