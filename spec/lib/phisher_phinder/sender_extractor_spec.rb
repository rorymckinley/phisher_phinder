# frozen_string_literal: true
require 'spec_helper'
require 'ipaddr'

RSpec.describe PhisherPhinder::SenderExtractor do
  let(:base_args) do
    {
      original_email: nil,
      original_headers: nil,
      original_body: nil,
      headers: nil,
      tracing_headers: {received: []},
      body: nil,
      authentication_headers: {authentication_results: []}
    }
  end
  let(:ip_1) { PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('10.0.0.1'), geoip_ip_data: nil) }
  let(:ip_2) { PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('10.0.0.2'), geoip_ip_data: nil) }
  let(:ip_3) { PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('10.0.0.3'), geoip_ip_data: nil) }
  let(:ip_4) { PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('10.0.0.4'), geoip_ip_data: nil) }
  let(:ip_5) { PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('10.0.0.5'), geoip_ip_data: nil) }
  let(:ip_6) { PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('10.0.0.6'), geoip_ip_data: nil) }
  let(:ip_7) { PhisherPhinder::ExtendedIp.new(ip_address: IPAddr.new('10.0.0.7'), geoip_ip_data: nil) }

  describe 'authentication_senders' do
    it 'extracts sender information from the authentication results' do
      args = base_args.merge(
        {
          authentication_headers: {
            authentication_results: [
              {authserv_id: 'foo.host', spf: {result: :pass, ip: ip_1, from: 'foo@test.com'}},
              {authserv_id: 'bar.host', spf: {result: :neutral, ip: ip_2, from: 'bar@test.com'}},
              {authserv_id: 'baz.host', spf: {result: :fail, ip: ip_3, from: 'baz@test.com'}},
            ]
          }
        }
      )

      mail = PhisherPhinder::Mail.new(**args)

      result = subject.extract(mail)

      expect(result[:authentication_senders]).to eql({
        hosts: [
          {entry_type: :ip, host: ip_1, spf: {present: true, trusted: true}},
          {entry_type: :ip, host: ip_2, spf: {present: true, trusted: false}},
          {entry_type: :ip, host: ip_3, spf: {present: true, trusted: false}},
        ],
        email_addresses: [
          {email_address: 'foo@test.com', spf: {present: true, trusted: true, result: :pass}},
          {email_address: 'bar@test.com', spf: {present: true, trusted: false, result: :neutral}},
          {email_address: 'baz@test.com', spf: {present: true, trusted: false, result: :fail}},
        ]
      })
    end

    it 'returns empty results if there are no authentication headers' do
      mail = PhisherPhinder::Mail.new(**base_args)

      result = subject.extract(mail)

      expect(result[:authentication_senders]).to eql({hosts: [], email_addresses: []})
    end

    it 'ignores entries from authservs that have already been processed' do
      args = base_args.merge(
        {
          authentication_headers: {
            authentication_results: [
              {authserv_id: 'foo.host', spf: {result: :pass, ip: ip_1, from: 'foo@test.com'}},
              {authserv_id: 'bar.host', spf: {result: :neutral, ip: ip_2, from: 'bar@test.com'}},
              {authserv_id: 'foo.host', spf: {result: :fail, ip: ip_3, from: 'baz@test.com'}},
              {authserv_id: 'fizz.host', spf: {result: :fail, ip: ip_4, from: 'fizz@test.com'}},
            ]
          }
        }
      )

      mail = PhisherPhinder::Mail.new(**args)

      result = subject.extract(mail)

      expect(result[:authentication_senders]).to eql({
        hosts: [
          {entry_type: :ip, host: ip_1, spf: {present: true, trusted: true}},
          {entry_type: :ip, host: ip_2, spf: {present: true, trusted: false}},
          {entry_type: :ip, host: ip_4, spf: {present: true, trusted: false}},
        ],
        email_addresses: [
          {email_address: 'foo@test.com', spf: {present: true, trusted: true, result: :pass}},
          {email_address: 'bar@test.com', spf: {present: true, trusted: false, result: :neutral}},
          {email_address: 'fizz@test.com', spf: {present: true, trusted: false, result: :fail}},
        ]
      })
    end

    it 'does not allow an untrusted entry to overwrite a trusted entry' do
      args = base_args.merge(
        {
          authentication_headers: {
            authentication_results: [
              {authserv_id: 'foo.host', spf: {result: :pass, ip: ip_1, from: 'foo@test.com'}},
              {authserv_id: 'bar.host', spf: {result: :neutral, ip: ip_2, from: 'bar@test.com'}},
              {authserv_id: 'baz.host', spf: {result: :fail, ip: ip_3, from: 'foo@test.com'}},
              {authserv_id: 'fizz.host', spf: {result: :fail, ip: ip_4, from: 'fizz@test.com'}},
            ]
          }
        }
      )

      mail = PhisherPhinder::Mail.new(**args)

      result = subject.extract(mail)

      expect(result[:authentication_senders]).to eql({
        hosts: [
          {entry_type: :ip, host: ip_1, spf: {present: true, trusted: true}},
          {entry_type: :ip, host: ip_2, spf: {present: true, trusted: false}},
          {entry_type: :ip, host: ip_3, spf: {present: true, trusted: false}},
          {entry_type: :ip, host: ip_4, spf: {present: true, trusted: false}},
        ],
        email_addresses: [
          {email_address: 'foo@test.com', spf: {present: true, trusted: true, result: :pass}},
          {email_address: 'bar@test.com', spf: {present: true, trusted: false, result: :neutral}},
          {email_address: 'fizz@test.com', spf: {present: true, trusted: false, result: :fail}},
        ]
      })
    end
  end

  describe 'tracing_senders' do
    it 'builds a chain of senders from the tracing headers' do
      args = base_args.merge(
        {
          authentication_headers: {
            authentication_results: [
              {authserv_id: 'foo.host', spf: {result: :pass, ip: ip_1, from: 'foo@test.com'}},
              {authserv_id: 'bar.host', spf: {result: :neutral, ip: ip_2, from: 'bar@test.com'}},
              {authserv_id: 'baz.host', spf: {result: :fail, ip: ip_3, from: 'baz@test.com'}},
            ]
          },
          tracing_headers: {
            received: [
              {
                sender: {host: 'notchain1.test', ip: ip_2},
                recipient: 'bar.host'
              },
              {
                sender: {host: 'chain1.test', ip: ip_1},
                recipient: 'foo.host'
              },
              {
                sender: {host: 'chain2.test', ip: ip_6},
                recipient: 'chain1.test'
              },
              {
                sender: {host: 'chain3.test', ip: ip_7},
                recipient: 'chain2.test'
              },
              {
                sender: {host: 'notchain2.test', ip: ip_3},
                recipient: 'notchain1.test'
              },
              {
                sender: {host: 'chain4.test', ip: ip_4},
                recipient: 'chain3.test'
              }
            ]
          }
        }
      )

      mail = PhisherPhinder::Mail.new(**args)

      result = subject.extract(mail)

      expect(result[:tracing_senders]).to eql([
        {host: 'chain1.test', ip: ip_1}, {host: 'chain2.test', ip: ip_6}, {host: 'chain3.test', ip: ip_7}
      ])
    end

    it 'skips over entries without a sender as long as it is before the start of a chain' do
      args = base_args.merge(
        {
          authentication_headers: {
            authentication_results: [
              {authserv_id: 'foo.host', spf: {result: :pass, ip: ip_1, from: 'foo@test.com'}},
              {authserv_id: 'bar.host', spf: {result: :neutral, ip: ip_2, from: 'bar@test.com'}},
              {authserv_id: 'baz.host', spf: {result: :fail, ip: ip_3, from: 'baz@test.com'}},
            ]
          },
          tracing_headers: {
            received: [
              {
                sender: {host: 'notchain1.test', ip: ip_2},
                recipient: 'bar.host'
              },
              {
                recipient: 'nosender.host'
              },
              {
                sender: {host: 'chain1.test', ip: ip_1},
                recipient: 'foo.host'
              },
              {
                sender: {host: 'chain2.test', ip: ip_6},
                recipient: 'chain1.test'
              },
              {
                recipient: 'anothernosender.host'
              },
              {
                sender: {host: 'chain3.test', ip: ip_7},
                recipient: 'chain2.test'
              },
              {
                sender: {host: 'notchain2.test', ip: ip_3},
                recipient: 'notchain1.test'
              },
              {
                sender: {host: 'chain4.test', ip: ip_4},
                recipient: 'chain3.test'
              }
            ]
          }
        }
      )

      mail = PhisherPhinder::Mail.new(**args)

      result = subject.extract(mail)

      expect(result[:tracing_senders]).to eql([
        {host: 'chain1.test', ip: ip_1}, {host: 'chain2.test', ip: ip_6}
      ])

    end
  end
end
