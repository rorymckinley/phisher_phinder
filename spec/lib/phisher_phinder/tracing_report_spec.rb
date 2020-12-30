# frozen_string_literal: true

RSpec.describe PhisherPhinder::TracingReport do
  let(:ip_1) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.1', geoip_ip_data: '1') }
  let(:ip_2) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.2', geoip_ip_data: '1') }
  let(:ip_3) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.3', geoip_ip_data: '1') }
  let(:ip_4) { PhisherPhinder::ExtendedIp.new(ip_address: '10.0.0.4', geoip_ip_data: '1') }
  let(:mail) do
    PhisherPhinder::Mail.new(
      original_email: '',
      original_headers: '',
      original_body: '',
      headers: [],
      tracing_headers: {
        received: received_headers
      },
      body: '',
      authentication_headers: {
        received_spf: received_spf
      }
    )
  end
  let(:received_headers) { [] }

  subject { described_class.new(mail) }

  describe 'authentication' do
    describe 'successful SPF check' do
      let(:received_spf) do
        [
          {
            result: :pass,
            ip: ip_3,
            mailfrom: 'foo@test.com'
          }
        ]
      end

      it 'indicates that the SPF check was successful' do
        report = subject.report

        expect(report[:authentication]).to eql({
          mechanisms: [:spf],
          spf: {success: true, from_address: 'foo@test.com', ip: ip_3},
        })
      end
    end

    describe 'neutral SPF check' do
      let(:received_spf) do
        [
          {
            result: :neutral,
            ip: ip_3,
            mailfrom: 'foo@test.com'
          }
        ]
      end

      it 'indicates that the SPF check was unsuccessful' do
        report = subject.report

        expect(report[:authentication]).to eql({
          mechanisms: [:spf],
          spf: {success: false, from_address: 'foo@test.com', ip: ip_3},
        })
      end
    end

    describe 'fail SPF check' do
      let(:received_spf) do
        [
          {
            result: :fail,
            ip: ip_3,
            mailfrom: 'foo@test.com'
          }
        ]
      end

      it 'indicates that the SPF check was unsuccessful' do
        report = subject.report

        expect(report[:authentication]).to eql({
          mechanisms: [:spf],
          spf: {success: false, from_address: 'foo@test.com', ip: ip_3},
        })
      end
    end

    describe 'multiple `received_spf` entries' do
      let(:received_spf) do
        [
          {
            result: :fail,
            ip: ip_3,
            mailfrom: 'foo@test.com'
          },
          {
            result: :pass,
            ip: ip_4,
            mailfrom: 'bar@test.com'
          }
        ]
      end

      it 'uses the first entry in the result set' do
        report = subject.report

        expect(report[:authentication]).to eql({
          mechanisms: [:spf],
          spf: {success: false, from_address: 'foo@test.com', ip: ip_3},
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
    let(:received_spf) do
      [
        {
          result: :poass,
          ip: ip_3,
          mailfrom: 'foo@test.com'
        },
      ]
    end

    it 'starts the list of tracing headers from the first tracing header that matches auth results' do
      report = subject.report

      expect(report[:tracing]).to eql([
        {sender: {host: 'c', ip: ip_3}},
        {sender: {host: 'd', ip: ip_4}},
      ])
    end
  end
end
