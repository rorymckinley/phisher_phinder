require 'spec_helper'
require 'pry'

RSpec.describe Overphishing::MailParser do
  let(:complete_mail_contents) { IO.read(File.join(FIXTURE_PATH, 'mail_1.txt')) }
  let(:simple_mail_contents) { IO.read(File.join(FIXTURE_PATH, 'mail_2.txt')) }
  let(:original_mail_body) { "This is the body\n" }
  let(:original_mail_headers) do
    "Delivered-To: dummy@test.com\n" +
    "Received: by 2002:a4a:d031:0:0:0:0:0 with SMTP id w17csp2701290oor;\n" +
    "        Sat, 25 Apr 2020 22:14:05 -0700 (PDT)"
  end
  let(:parsed_complete_mail) { described_class.new.parse(complete_mail_contents) }
  let(:parsed_simple_mail) { described_class.new.parse(simple_mail_contents) }
  let(:received_header_value) do
    "by 2002:a4a:d031:0:0:0:0:0 with SMTP id w17csp2701290oor; Sat, 25 Apr 2020 22:14:05 -0700 (PDT)"
  end

  describe 'parsing an email' do
    describe 'the parsed mail' do
      it 'provides access to the original text of the parsed email' do
        expect(parsed_simple_mail.original_email).to eql simple_mail_contents
      end

      it 'separates the original headers and body' do
        expect(parsed_simple_mail.original_headers).to eql original_mail_headers
        expect(parsed_simple_mail.original_body).to eql original_mail_body
      end

      it 'extracts headers' do
        expect(parsed_simple_mail.headers.keys.sort).to eql [:delivered_to, :received]
        expect(parsed_simple_mail.headers[:delivered_to]).to eql 'dummy@test.com'
        expect(parsed_simple_mail.headers[:received]).to eql received_header_value
      end

      it 'combines header values when there are multiple entries' do
        expect(parsed_complete_mail.headers[:reply_to]).to eql([
          '<UYL4O05CKRMOCGB@8179.832>',
          '<093EQZIAIZEMNGT@3121.295>',
          '<0R6SXF0LLNIAF5Y@1739.842>, <3XUGT4L0VPPDYAB@2899.232>',
          'a@dodgy.com, b@dodgy.com, c@dodgy.com',
          '<YL1J605V6XP25G7@0418.287>',
          '<N3M8G6FZ1PCWHSB@2624.698>',
          '<6LCNMRYZWC11Z8C@1699.813>'
        ])
      end
    end
  end
end
