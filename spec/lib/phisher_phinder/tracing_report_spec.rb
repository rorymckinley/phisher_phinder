# frozen_string_literal: true

RSpec.describe PhisherPhinder::TracingReport do
  let(:bar_hyperlink) { PhisherPhinder::BodyHyperlink.new('http://test.bar', 'Bar') }
  let(:host_information_finder) do
    instance_double(PhisherPhinder::HostInformationFinder).tap do |dbl|
      allow(dbl).to receive(:information_for) do |arg|
        case arg
          when ip_2
            {abuse_contacts: ['ip_2@test.zzz']}
          when ip_3
            {abuse_contacts: ['ip_3@test.zzz']}
          when ip_4
            {abuse_contacts: ['ip_4@test.zzz']}
          when 'b'
            {abuse_contacts: ['b@test.zzz']}
          when 'c'
            {abuse_contacts: ['c@test.zzz']}
          when 'd'
            {abuse_contacts: ['d@test.zzz']}
        end
      end
    end
  end
  let(:foo_hyperlink) { PhisherPhinder::BodyHyperlink.new('http://test.foo', 'Foo') }
  let(:from_entries) { [{data: 'from_1@test.zzz'}, {data: 'from_2@test.zzz'}] }
  let(:link_explorer) do
    instance_double(PhisherPhinder::LinkExplorer).tap do |dbl|
      allow(dbl).to receive(:explore) do |arg|
        case arg
        when bar_hyperlink
          [{bar: :data}, {bar_one: :data}]
        when foo_hyperlink
          [{foo: :data}, {foo_one: :data}]
        when mail_hyperlink_1
          ['mail_1@test.com', 'mail_2@test.com', 'mail_3@test.com']
        when mail_hyperlink_2
          ['mail_3@test.com', 'mail_4@test.com']
        end
      end
    end
  end
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
      body: {
        html: '<a href="http://test.foo">Foo</a>' +
        '<a href="mailto:mail_1@test.com">Mail One</a>' +
        '<a href="http://test.bar">Bar</a>' +
        '<a href="mailto:mail_3@test.com">Mail Three</a>' +
        '<a href="http://test.foo">Foo</a>'
      },
      authentication_headers: {
        received_spf: received_spf
      }
    )
  end
  let(:mail_hyperlink_1) { PhisherPhinder::BodyHyperlink.new('mailto:mail_1@test.com', 'Mail One') }
  let(:mail_hyperlink_2) { PhisherPhinder::BodyHyperlink.new('mailto:mail_3@test.com', 'Mail Three') }
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

  subject do
    described_class.new(mail: mail, host_information_finder: host_information_finder, link_explorer: link_explorer)
  end

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

    describe 'retrieving contact information for the senders' do
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

      it 'looks up contact details for each sender entry' do
        expect(host_information_finder).to receive(:information_for).with('c')
        expect(host_information_finder).to receive(:information_for).with(ip_3)
        expect(host_information_finder).to receive(:information_for).with('d')
        expect(host_information_finder).to receive(:information_for).with(ip_4)

        report = subject.report
      end
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
          {
            sender: {host: 'c', ip: ip_3},
            sender_contact_details: {host: {email: ['c@test.zzz']}, ip: {email: ['ip_3@test.zzz']}}
          },
          {
            sender: {host: 'd', ip: ip_4},
            sender_contact_details: {host: {email: ['d@test.zzz']}, ip: {email: ['ip_4@test.zzz']}}
          },
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
          {
            sender: {host: 'b', ip: ip_2},
            sender_contact_details: {host: {email: ['b@test.zzz']}, ip: {email: ['ip_2@test.zzz']}}
          },
          {
            sender: {host: 'c', ip: ip_3},
            sender_contact_details: {host: {email: ['c@test.zzz']}, ip: {email: ['ip_3@test.zzz']}}
          },
          {
            sender: {host: 'd', ip: ip_4},
            sender_contact_details: {host: {email: ['d@test.zzz']}, ip: {email: ['ip_4@test.zzz']}}
          },
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
        body: {html: ''},
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
      report = described_class.new(
        mail: mail_without_origin_headers, host_information_finder: host_information_finder, link_explorer: link_explorer
      ).report

      expect(report[:origin]).to eql({
        from: [],
        return_path: [],
        message_id: []
      })
    end
  end

  describe 'content_hyperlinks' do
    it 'passes each of the unique hyperlinks found in the mail body to the hyperlink explorer' do
      expect(link_explorer).to receive(:explore).with(foo_hyperlink)
      expect(link_explorer).to receive(:explore).with(bar_hyperlink)

      subject.report
    end

    it 'includes urls that are linked within the mail body' do
      report = subject.report

      expect(report[:content][:linked_urls]).to eql(
        [[{foo: :data}, {foo_one: :data}], [{bar: :data}, {bar_one: :data}]]
      )
    end

    it 'includes any email address that are linked to within the body' do
      report = subject.report

      expect(report[:content][:linked_email_addresses]).to eql(
        ['mail_1@test.com', 'mail_2@test.com', 'mail_3@test.com', 'mail_4@test.com']
      )
    end
  end
end
