# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::Display do
  describe '#display_report' do
    let(:ip_1) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.1', geoip_ip_data: '1') }
    let(:ip_2) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.2', geoip_ip_data: '1') }
    let(:ip_3) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.3', geoip_ip_data: '1') }
    let(:ip_4) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.4', geoip_ip_data: '1') }
    let(:ip_5) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.5', geoip_ip_data: '1') }
    let(:ip_6) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.6', geoip_ip_data: '1') }
    let(:ip_7) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.7', geoip_ip_data: '1') }
    let(:ip_8) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.8', geoip_ip_data: '1') }
    let(:input) do
      {
        authentication: {
          spf: {
            ip: ip_7,
            from_address: 'foo@test.zzz',
            client_ip: ip_8,
            success: true
          }
        },
        origin: {
          from: ['from_1@test.zzz', 'from_2@test.zzz'],
          return_path: ['rp_1@test.zzz', 'rp_2@test.zzz'],
          message_id: ['m_id_1', 'm_id_2']
        },
        tracing: [
          {
            sender: {ip: ip_1, host: 'foo.bar'},
            advertised_sender: ip_2,
            recipient: ip_3,
            sender_contact_details: {
              host: {email: ['host_1@test.zzz', 'host_2@test.zzz']},
              ip: {email: ['ip_1@test.zzz', 'ip_2@test.zzz']}
            }
          },
          {
            sender: {ip: ip_4, host: 'baz.bar'},
            advertised_sender: ip_5,
            recipient: ip_6,
            sender_contact_details: {
              host: {email: ['host_3@test.zzz', 'host_4@test.zzz']},
              ip: {email: ['ip_3@test.zzz', 'ip_4@test.zzz']}
            }
          }
        ],
        content: {
          linked_urls: [],
        }
      }
    end

    describe 'tracing data' do
      let(:input_with_helo) do
        {
          authentication: {
            spf: {}
          },
          origin: {
            from: [],
            message_id: [],
            return_path: []
          },
          tracing: [
            {
              sender: {ip: ip_1, host: 'foo.bar'},
              helo: ip_2,
              recipient: ip_3,
              sender_contact_details: {
                host: {email: ['host_1@test.zzz', 'host_2@test.zzz']},
                ip: {email: ['ip_1@test.zzz', 'ip_2@test.zzz']}
              }
            },
          ],
          content: {
            linked_urls: [],
          }
        }
      end
      let(:input_with_dirty_contact_details) do
        {
          authentication: {
            spf: {}
          },
          origin: {
            from: [],
            message_id: [],
            return_path: []
          },
          tracing: [
            {
              sender: {ip: ip_1, host: 'foo.bar'},
              helo: ip_2,
              recipient: ip_3,
              sender_contact_details: {
                host: {email: ['<host_1@test.zzz>', '<host_2@test.zzz>,']},
                ip: {email: ['<ip_1@test.zzz>', '<ip_2@test.zzz>,']}
              }
            },
          ],
          content: {
            linked_urls: []
          }
        }
      end

      it 'outputs a representation of the tracing data' do
        expect do
          subject.display_report(input)
        end.to output(/Sender IP.+IP Contacts.+Sender Host.+Host Contact.+Advertised Sender.+Recipient/).to_stdout
        expect do
          subject.display_report(input)
        end.to output(
          /10\.0\.0\.1.+ip_1@test.zzz, ip_2@test.zzz.+foo\.bar.+host_1@test.zzz, host_2@test.zzz.+10.0.0.2.+10\.0\.0\.3/
        ).to_stdout
        expect do
          subject.display_report(input)
        end.to output(
          /10\.0\.0\.4.+ip_3@test.zzz, ip_4@test.zzz.+baz\.bar.+host_3@test.zzz, host_4@test.zzz.+10.0.0.5.+10\.0\.0\.6/
        ).to_stdout
      end

      it 'uses helo data if no advertised sender is provided' do
        expect do
          subject.display_report(input_with_helo)
        end.to output(
          /10\.0\.0\.1.+ip_1@test.zzz, ip_2@test.zzz.+foo\.bar.+host_1@test.zzz, host_2@test.zzz.+10.0.0.2.+10\.0\.0\.3/
        ).to_stdout
      end

      it 'cleans up any formatting characters' do
        expect do
          subject.display_report(input_with_dirty_contact_details)
        end.to output(
          /10\.0\.0\.1.+ip_1@test.zzz, ip_2@test.zzz.+foo\.bar.+host_1@test.zzz, host_2@test.zzz.+10.0.0.2.+10\.0\.0\.3/
        ).to_stdout
      end
    end

    describe 'SPF data' do
      let(:input_unsuccessful_spf) do
        {
          authentication: {
            spf: {
              ip: ip_7,
              from_address: 'foo@test.zzz',
              client_ip: ip_8,
              success: false
            }
          },
          origin: {
            from: [],
            message_id: [],
            return_path: []
          },
          tracing: [],
          content: {
            linked_urls: []
          }
        }
      end

      it 'outputs a representation of the SPF data' do
        expect do
          subject.display_report(input)
        end.to output(/SPF Pass\?.+Sender Host.+From Address/).to_stdout
        expect do
          subject.display_report(input)
        end.to output(/Yes.+10.0.0.7.+foo@test.zzz/).to_stdout
      end

      it 'correctly indicates the SPF result status' do
        expect do
          subject.display_report(input_unsuccessful_spf)
        end.to output(/No.+10.0.0.7.+foo@test.zzz/).to_stdout
      end
    end

    describe 'origin data' do
      it 'outputs a representation of the origin data' do
        expect do
          subject.display_report(input)
        end.to output(/From.+from_1@test\.zzz, from_2@test\.zzz/).to_stdout
        expect do
          subject.display_report(input)
        end.to output(/Message ID.+m_id_1, m_id_2/).to_stdout
        expect do
          subject.display_report(input)
        end.to output(/Return Path.+rp_1@test.zzz, rp_2@test.zzz/).to_stdout
      end
    end

    describe 'content_hyperlinks' do
      let(:host_information_0) do
        {
          abuse_contacts: ['a@b.com', 'b@c.com'],
          creation_date: now - 100,
        }
      end
      let(:host_information_1) do
        {
          abuse_contacts: ['c@b.com', 'd@c.com'],
          creation_date: nil,
        }
      end
      let(:host_information_2) do
        {
          abuse_contacts: ['d@b.com', 'e@c.com'],
          creation_date: now - 80,
        }
      end
      let(:host_information_3) do
        {
          abuse_contacts: ['f@b.com', 'g@c.com'],
          creation_date: now - 70,
        }
      end
      let(:host_information_4) do
        {
          abuse_contacts: ['g@b.com', 'h@c.com'],
          creation_date: now - 60,
        }
      end
      let(:input) do
        {
          authentication: {
            spf: {
              ip: ip_7,
              from_address: 'foo@test.zzz',
              client_ip: ip_8,
              success: false
            }
          },
          origin: {
            from: [],
            message_id: [],
            return_path: []
          },
          tracing: [],
          content: {
            linked_urls: [
              [
                PhisherPhinder::LinkHost.new(
                  url: URI.parse(url_0),
                  body: '',
                  status_code: 301,
                  headers: {},
                  host_information: host_information_0,
                ),
                PhisherPhinder::LinkHost.new(
                  url: URI.parse(url_1),
                  body: '',
                  status_code: 301,
                  headers: {},
                  host_information: host_information_1,
                ),
                PhisherPhinder::LinkHost.new(
                  url: URI.parse(url_2),
                  body: '',
                  status_code: 200,
                  headers: {},
                  host_information: host_information_2,
                )
              ],
              [
                PhisherPhinder::LinkHost.new(
                  url: URI.parse(url_3),
                  body: '',
                  status_code: 301,
                  headers: {},
                  host_information: host_information_3,
                ),
                PhisherPhinder::LinkHost.new(
                  url: URI.parse(url_4),
                  body: '',
                  status_code: 200,
                  headers: {},
                  host_information: host_information_4,
                ),
              ]
            ]
          }
        }
      end
      let(:now) { Time.now }
      let(:url_0) { 'https://foo.bar/buzz?biz=boz' }
      let(:url_1) { 'https://biz.bar/foo?bar=biz' }
      let(:url_2) { 'https://boz.bar/buzz?bur=baz' }
      let(:url_3) { 'https://baz.bar/foo?bur=baz' }
      let(:url_4) { 'https://bez.bar/buzz?bur=baz' }

      it 'displays the hyperlinks found in the mail body' do
        expect do
          subject.display_report(input)
        end.to output(
          %r{
            #{host_entry('https://foo.bar/buzz?biz=boz' , host_information_0)}
            \t#{host_entry(url_1, host_information_1)}
            \t\t#{host_entry(url_2, host_information_2)}
          }mx
        ).to_stdout

        expect do
          subject.display_report(input)
        end.to output(
          %r{
            #{host_entry(url_3, host_information_3)}
            \t#{host_entry(url_4, host_information_4)}
          }mx
        ).to_stdout
      end

      def host_entry(url, info)
        escaped_url = url.gsub(/\?/, '\?')
        creation_date = info[:creation_date] ? info[:creation_date].strftime('%Y-%m-%d\\s%H:%M:%S') : nil

        "#{escaped_url}\\s\\(#{creation_date}\\)\\s\\[#{info[:abuse_contacts].join(',\\s')}\\]\\n"
      end
    end
  end
end
