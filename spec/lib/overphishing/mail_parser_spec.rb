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

      it 'extracts headers and includes the header sequence' do
        expect(parsed_simple_mail.headers.keys.sort).to eql [:delivered_to, :received]
        expect(parsed_simple_mail.headers[:delivered_to]).to eql({data: 'dummy@test.com', sequence: 1})
        expect(parsed_simple_mail.headers[:received]).to eql({data: received_header_value, sequence: 0})
      end

      it 'combines header values when there are multiple entries' do
        expect(parsed_complete_mail.headers[:reply_to]).to eql([
          {data: '<UYL4O05CKRMOCGB@8179.832>', sequence: 15},
          {data: '<093EQZIAIZEMNGT@3121.295>', sequence: 13},
          {data: '<0R6SXF0LLNIAF5Y@1739.842>, <3XUGT4L0VPPDYAB@2899.232>', sequence: 10},
          {data: 'a@dodgy.com, b@dodgy.com, c@dodgy.com', sequence: 7},
          {data: '<YL1J605V6XP25G7@0418.287>', sequence: 4},
          {data: '<N3M8G6FZ1PCWHSB@2624.698>', sequence: 2},
          {data: '<6LCNMRYZWC11Z8C@1699.813>', sequence: 0}
        ])
      end

      it 'parses and sets the tracing headers' do
        expect(parsed_complete_mail.tracing_headers[:received]).to eql([
          {
            advertised_sender: nil,
            id: 'w17csp2701290oor',
            partial: true,
            protocol: 'SMTP',
            recipient: '2002:a4a:d031:0:0:0:0:0',
            recipient_mailbox: 'anotherdummy@test.com',
            sender: nil,
            time: Time.new(2020, 4, 25, 22, 14, 7, '-07:00')
          },
          {
            advertised_sender: nil,
            id: 'w6mr17215337plq.173.1587878045528',
            partial: true,
            protocol: 'SMTP',
            recipient: '2002:a17:902:a706::',
            recipient_mailbox: nil,
            sender: nil,
            time: Time.new(2020, 4, 25, 22, 14, 6, '-07:00')
          },
          {
            advertised_sender: 'not.real.com',
            id: 'b201si8173212pfb.88.2020.04.25.22.14.05',
            partial: false,
            protocol: 'ESMTP',
            recipient: 'mx.google.com',
            recipient_mailbox: 'dummy@test.com',
            sender: {host: 'my.dodgy.host.com', ip: '10.0.0.1'},
            time: Time.new(2020, 4, 25, 22, 14, 5, '-07:00')
          },
          {
            advertised_sender: 'still.not.real.com',
            id: nil,
            partial: true,
            protocol: nil,
            recipient: nil,
            recipient_mailbox: nil,
            sender: {host: 'another.dodgy.host.com', ip: '10.0.0.2'},
            time: nil
          }
        ])
      end
    end
  end
end
