# frozen_string_literal: true

RSpec.describe PhisherPhinder::TracingReport do
  let(:from_entries) { [{data: 'from_1@test.zzz'}, {data: 'from_2@test.zzz'}] }
  let(:ip_1) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.1', geoip_ip_data: '1') }
  let(:ip_2) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.2', geoip_ip_data: '1') }
  let(:ip_3) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.3', geoip_ip_data: '1') }
  let(:ip_4) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.4', geoip_ip_data: '1') }
  let(:mail) do
    PhisherPhinder::Mail.new(
      original_email: '',
      original_headers: '',
      original_body: '',
      headers: {
        from: from_entries,
        return_path: return_path_entries,
        message_id: message_id_entries
      },
      tracing_headers: {
        received: received_headers
      },
      body: '',
      authentication_headers: {
        received_spf: received_spf
      }
    )
  end
  let(:message_id_entries) { [{data: 'message_id_1'}, {data: 'message_id_2'}] }
  let(:received_headers) { [] }
  let(:received_spf) do
    [
      {
        result: :pass,
        ip: ip_3,
        mailfrom: 'foo@test.com',
        client_ip: ip_1,
      }
    ]
  end
  let(:return_path_entries) { [{data: 'rp_1@test.zzz'}, {data: 'rp_2@test.zzz'}] }

  subject { described_class.new(mail) }

  describe 'authentication' do
    describe 'successful SPF check' do
      let(:received_spf) do
        [
          {
            result: :pass,
            ip: ip_3,
            mailfrom: 'foo@test.com',
            client_ip: ip_1,
          }
        ]
      end

      it 'indicates that the SPF check was successful' do
        report = subject.report

        expect(report[:authentication]).to eql({
          mechanisms: [:spf],
          spf: {success: true, from_address: 'foo@test.com', ip: ip_3, client_ip: ip_1},
        })
      end
    end

    describe 'neutral SPF check' do
      let(:received_spf) do
        [
          {
            result: :neutral,
            ip: ip_3,
            mailfrom: 'foo@test.com',
            client_ip: ip_1,
          }
        ]
      end

      it 'indicates that the SPF check was unsuccessful' do
        report = subject.report

        expect(report[:authentication]).to eql({
          mechanisms: [:spf],
          spf: {success: false, from_address: 'foo@test.com', ip: ip_3, client_ip: ip_1},
        })
      end
    end

    describe 'fail SPF check' do
      let(:received_spf) do
        [
          {
            result: :fail,
            ip: ip_3,
            mailfrom: 'foo@test.com',
            client_ip: ip_1,
          }
        ]
      end

      it 'indicates that the SPF check was unsuccessful' do
        report = subject.report

        expect(report[:authentication]).to eql({
          mechanisms: [:spf],
          spf: {success: false, from_address: 'foo@test.com', ip: ip_3, client_ip: ip_1},
        })
      end
    end

    describe 'multiple `received_spf` entries' do
      let(:received_spf) do
        [
          {
            result: :fail,
            ip: ip_3,
            mailfrom: 'foo@test.com',
            client_ip: ip_1,
          },
          {
            result: :pass,
            ip: ip_4,
            mailfrom: 'bar@test.com',
            client_ip: ip_2,
          }
        ]
      end

      it 'uses the first entry in the result set' do
        report = subject.report

        expect(report[:authentication]).to eql({
          mechanisms: [:spf],
          spf: {success: false, from_address: 'foo@test.com', ip: ip_3, client_ip: ip_1},
        })
      end
    end
  end

  describe 'tracing' do
    let(:received_headers) do
      [
        {
          sender: {host: 'a', ip: ip_1}
        },
        {
          sender: {host: 'b', ip: ip_2}
        },
        {
          sender: {host: 'c', ip: ip_3}
        },
        {
          sender: {host: 'd', ip: ip_4}
        },
      ]
    end

    describe 'SPF record has a IP entry' do
      let(:received_spf) do
        [
          {
            result: :pass,
            ip: ip_3,
            mailfrom: 'foo@test.com',
            client_ip: ip_1
          },
        ]
      end

      it 'starts the list of tracing headers from the first tracing header that matches the IP' do
        report = subject.report

        expect(report[:tracing]).to eql([
          {sender: {host: 'c', ip: ip_3}},
          {sender: {host: 'd', ip: ip_4}},
        ])
      end
    end

    describe 'SPF record has no ip entry but does have a client-ip entry' do
      let(:received_spf) do
        [
          {
            result: :pass,
            ip: nil,
            mailfrom: 'foo@test.com',
            client_ip: ip_2
          },
        ]
      end

      it 'starts the list of tracing headers from the first tracing header that matches auth results' do
        report = subject.report

        expect(report[:tracing]).to eql([
          {sender: {host: 'b', ip: ip_2}},
          {sender: {host: 'c', ip: ip_3}},
          {sender: {host: 'd', ip: ip_4}},
        ])
      end
    end
  end

  describe 'origin' do
    let(:mail_without_origin_headers) do
      PhisherPhinder::Mail.new(
        original_email: '',
        original_headers: '',
        original_body: '',
        headers: { },
        tracing_headers: {
          received: received_headers
        },
        body: '',
        authentication_headers: {
          received_spf: received_spf
        }
      )
    end

    it 'returns the origin information for the mail' do
      report = subject.report

      expect(report[:origin]).to eql({
        from: ['from_1@test.zzz', 'from_2@test.zzz'],
        return_path: ['rp_1@test.zzz', 'rp_2@test.zzz'],
        message_id: ['message_id_1', 'message_id_2']
      })
    end

    it 'returns empty collections if there are no origin headers available' do
      report = described_class.new(mail_without_origin_headers).report

      expect(report[:origin]).to eql({
        from: [],
        return_path: [],
        message_id: []
      })
    end
  end
end
