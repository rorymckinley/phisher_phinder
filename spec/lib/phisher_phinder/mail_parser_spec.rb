require 'spec_helper'
require 'ipaddr'

RSpec.describe PhisherPhinder::MailParser::Parser do
  let(:base64_mail_contents) { IO.read(File.join(FIXTURE_PATH, 'mail_base_64.txt')) }
  let(:complete_mail_contents) { IO.read(File.join(FIXTURE_PATH, 'mail_1.txt')) }
  let(:multipart_base64_mail_contents) { IO.read(File.join(FIXTURE_PATH, 'mail_base_64_multipart.txt')) }
  let(:simple_mail_contents) { IO.read(File.join(FIXTURE_PATH, 'mail_2.txt')) }
  let(:mail_with_utf8_subject_contents) { IO.read(File.join(FIXTURE_PATH, 'mail_utf8_subject.txt')) }
  let(:enriched_ip_1) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_2) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_3) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_4) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_5) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_6) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_7) { instance_double(PhisherPhinder::ExtendedIp) }
  let(:enriched_ip_factory) do
    instance_double(PhisherPhinder::ExtendedIpFactory).tap do |factory|
      allow(factory).to receive(:build) do |arg|
        case arg
        when '2002:a4a:d031:0:0:0:0:0'
          enriched_ip_1
        when '2002:a17:902:a706::'
          enriched_ip_2
        when '10.0.0.3'
          enriched_ip_3
        when '10.0.0.4'
          enriched_ip_4
        when '10.0.0.5'
          enriched_ip_5
        when '10.0.0.6'
          enriched_ip_6
        when '10.0.0.1'
          enriched_ip_7
        when 'mx.google.com'
          nil
        end
      end
    end
  end
  let(:original_mail_body) { "This is the body\n" }
  let(:original_mail_headers) do
    "Delivered-To: dummy@test.com\n" +
    "Received: by 2002:a4a:d031:0:0:0:0:0 with SMTP id w17csp2701290oor;\n" +
    "        Sat, 25 Apr 2020 22:14:05 -0700 (PDT)"
  end
  let(:parsed_mail_with_base64_body) do
    described_class.new(enriched_ip_factory, ENV.fetch('LINE_ENDING_TYPE')).parse(base64_mail_contents)
  end
  let(:parsed_mail_with_multipart_base64_body) do
    described_class.new(enriched_ip_factory, ENV.fetch('LINE_ENDING_TYPE')).parse(multipart_base64_mail_contents)
  end
  let(:parsed_complete_mail) do
    described_class.new(enriched_ip_factory, ENV.fetch('LINE_ENDING_TYPE')).parse(complete_mail_contents)
  end
  let(:parsed_simple_mail) do
    described_class.new(enriched_ip_factory, ENV.fetch('LINE_ENDING_TYPE')).parse(simple_mail_contents)
  end
  let(:parsed_mail_utf8_subject) do
    described_class.new(enriched_ip_factory, ENV.fetch('LINE_ENDING_TYPE')).parse(mail_with_utf8_subject_contents)
  end
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
        expect(parsed_simple_mail.headers[:delivered_to]).to eql([{data: 'dummy@test.com', sequence: 1}])
        expect(parsed_simple_mail.headers[:received]).to eql([{data: received_header_value, sequence: 0}])
      end

      it 'combines header values when there are multiple entries' do
        expect(parsed_complete_mail.headers[:reply_to]).to eql([
          {data: '<UYL4O05CKRMOCGB@8179.832>', sequence: 15},
          {data: '<093EQZIAIZEMNGT@3121.295>', sequence: 13},
          {data: '<0R6SXF0LLNIAF5Y@1739.842>, <3XUGT4L0VPPDYAB@2899.232>', sequence: 10},
          {data: 'a@dodgy.com, b@dodgy.com, c@dodgy.com', sequence: 7},
          {data: '<YL1J605V6XP25G7@0418.287>', sequence: 5},
          {data: '<N3M8G6FZ1PCWHSB@2624.698>', sequence: 3},
          {data: '<6LCNMRYZWC11Z8C@1699.813>', sequence: 1}
        ])
      end

      it 'parses and sets the tracing headers' do
        expect(parsed_complete_mail.tracing_headers[:received]).to eql([
          {
            advertised_sender: nil,
            helo: nil,
            id: 'w17csp2701290oor',
            partial: true,
            protocol: 'SMTP',
            recipient: enriched_ip_1,
            recipient_additional: nil,
            authenticated_as: nil,
            recipient_mailbox: 'anotherdummy@test.com',
            sender: nil,
            starttls: nil,
            time: Time.new(2020, 4, 25, 22, 14, 8, '-07:00')
          },
          {
            advertised_sender: nil,
            helo: nil,
            id: 'w6mr17215337plq.173.1587878045528',
            partial: true,
            protocol: 'SMTP',
            recipient: enriched_ip_2,
            recipient_additional: nil,
            authenticated_as: nil,
            recipient_mailbox: nil,
            sender: nil,
            starttls: nil,
            time: Time.new(2020, 4, 25, 22, 14, 7, '-07:00')
          },
          {
            advertised_sender: 'probably.not.real.com',
            helo: nil,
            id: 'u23si16237783eds.526.2020.06.26.06.27.53',
            partial: false,
            protocol: 'ESMTPS',
            recipient: 'mx.google.com',
            recipient_additional: nil,
            authenticated_as: nil,
            recipient_mailbox: 'mannequin@test.com',
            sender: {host: nil, ip: enriched_ip_3},
            starttls: {version: 'TLS1_2', cipher: 'ECDHE-ECDSA-AES128-GCM-SHA256', bits: '128/128'},
            time: Time.new(2020, 4, 25, 22, 14, 6, '-07:00')
          },
          {
            advertised_sender: 'also.made.up',
            helo: nil,
            id: '3gJek488nka743gKRkR2nY',
            partial: true,
            protocol: 'SMTP',
            recipient: 'fuzzy.fake.com',
            recipient_additional: 'Fuzzy Corp',
            authenticated_as: nil,
            recipient_mailbox: nil,
            starttls: nil,
            sender: {host: nil, ip: enriched_ip_4},
            time: Time.new(2020, 4, 25, 22, 14, 5, '-07:00')
          },
          {
            advertised_sender: 'not.real.com',
            helo: nil,
            id: 'b201si8173212pfb.88.2020.04.25.22.14.05',
            partial: false,
            protocol: 'ESMTP',
            recipient: 'mx.google.com',
            recipient_additional: '8.14.7/8.14.7',
            authenticated_as: nil,
            recipient_mailbox: 'dummy@test.com',
            sender: {host: 'my.dodgy.host.com', ip: enriched_ip_5},
            starttls: nil,
            time: Time.new(2020, 4, 25, 22, 14, 4, '-07:00')
          },
          {
            advertised_sender: 'still.not.real.com',
            helo: nil,
            id: nil,
            partial: true,
            protocol: nil,
            recipient: nil,
            recipient_additional: nil,
            authenticated_as: nil,
            recipient_mailbox: nil,
            sender: {host: 'another.dodgy.host.com', ip: enriched_ip_6},
            starttls: nil,
            time: nil
          },
          {
            advertised_sender: 'root@localhost',
            helo: nil,
            id: '05QDRrso001911',
            partial: true,
            protocol: nil,
            recipient: 'still.dodgy.host.com',
            recipient_additional: '8.14.7/8.14.7/Submit',
            authenticated_as: nil,
            recipient_mailbox: nil,
            sender: {host: nil, ip: nil},
            starttls: nil,
            time: nil
          }
        ])
      end

      it 'stores the email body as plain text if no content type is specified' do
        expect(parsed_simple_mail.body).to eql({text: "This is the body\n", html: nil})
      end

      it 'stores the email body where the body is specified as plain text' do
        expect(parsed_complete_mail.body).to eql({text: "This is the body\n", html: nil})
      end

      it 'decodes the mail body if it is specified as base64-encoded' do
        expect(parsed_mail_with_base64_body.body).to eql({html: 'This is the base 64 body', text: nil})
      end

      it 'decodes the mail body if it is multipart-encoded' do
        expect(parsed_mail_with_multipart_base64_body.body).to eql(
          {
            html: 'ThreeFour',
            text: 'OneTwo'
          }
        )
      end

      it 'has a decoded subject if the original subject was UTF-8 Base64 encoded' do
        subject = parsed_mail_utf8_subject.headers[:subject].first[:data]
        expect(subject).to eql 'foõ ßæÞ'
      end

      it 'sets the authentication headers for the email (for now, only authentication-results)' do
        expect(parsed_complete_mail.authentication_headers).to eql(
          {
            authentication_results: [
              {
                authserv_id: 'mx.google.com',
                spf: {
                  result: :pass,
                  from: 'scam@my.dodgy.host.com',
                  ip: enriched_ip_7
                }
              }
            ]
          }
        )
      end
    end
  end
end
