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
            recipient: ip_3
          },
          {
            sender: {ip: ip_4, host: 'baz.bar'},
            advertised_sender: ip_5,
            recipient: ip_6
          }
        ]
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
            },
          ]
        }
      end

      it 'outputs a representation of the tracing data' do
        expect do
          subject.display_report(input)
        end.to output(/Sender IP.+Sender Host.+Advertised Sender.+Recipient/).to_stdout
        expect do
          subject.display_report(input)
        end.to output(/10\.0\.0\.1.+foo\.bar.+10.0.0.2.+10\.0\.0\.3/).to_stdout
        expect do
          subject.display_report(input)
        end.to output(/10\.0\.0\.4.+baz\.bar.+10.0.0.5.+10\.0\.0\.6/).to_stdout
      end

      it 'uses helo data if no advertised sender is provided' do
        expect do
          subject.display_report(input_with_helo)
        end.to output(/10\.0\.0\.1.+foo\.bar.+10.0.0.2.+10\.0\.0\.3/).to_stdout
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
          tracing: []
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
  end
end
