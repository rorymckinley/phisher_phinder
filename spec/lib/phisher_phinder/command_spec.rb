# frozen_string_literal: true
require 'spec_helper'
require 'timecop'

RSpec.describe PhisherPhinder::Command do
  describe '#report' do
    let(:host_information_finder) { instance_double(PhisherPhinder::HostInformationFinder) }
    let(:contents) { "foo" }
    let(:extractor) { instance_double(PhisherPhinder::WhoisEmailExtractor) }
    let(:geoip_settings) { {account_id: 'foo', license_key: 'bar'} }
    let(:host_response_policy) { PhisherPhinder::HostResponsePolicy.new }
    let(:link_explorer) { instance_double(PhisherPhinder::LinkExplorer) }
    let(:ip_factory) { instance_double(PhisherPhinder::ExtendedIpFactory) }
    let(:mail) { instance_double(PhisherPhinder::Mail) }
    let(:mail_parser) { instance_double(PhisherPhinder::MailParser::Parser, parse: mail) }
    let(:maxmind_client) { instance_double(MaxMind::GeoIP2::Client) }
    let(:null_client) { instance_double(PhisherPhinder::NullLookupClient) }
    let(:report_output) { {report: :output} }
    let(:tracing_report) { instance_double(PhisherPhinder::TracingReport, report: report_output) }
    let(:whois_client) { instance_double(Whois::Client) }
    let(:now) { Time.now }
    let(:options) { {line_ending: "\r\n", geoip_lookup: false} }

    before(:each) do
      allow(PhisherPhinder::NullLookupClient).to receive(:new).and_return(null_client)
      allow(PhisherPhinder::ExtendedIpFactory).to receive(:new).and_return(ip_factory)
      allow(PhisherPhinder::MailParser::Parser).to receive(:new).and_return(mail_parser)
      allow(PhisherPhinder::TracingReport).to receive(:new).and_return(tracing_report)
      allow(Whois::Client).to receive(:new).and_return(whois_client)
      allow(PhisherPhinder::WhoisEmailExtractor).to receive(:new).and_return(extractor)
      allow(PhisherPhinder::HostInformationFinder).to receive(:new).and_return(host_information_finder)
      allow(PhisherPhinder::LinkExplorer).to receive(:new).and_return(link_explorer)
    end

    describe 'initialising the ip lookup client' do
      it 'initialises a dummy client if geoip lookup is not enabled' do
        expect(PhisherPhinder::NullLookupClient).to receive(:new).and_return(maxmind_client)

        subject.report(contents, **options)
      end

      it 'initialises the cached ip client if geoip lookup is enabled' do
        Timecop.freeze(now) do
          expect(MaxMind::GeoIP2::Client).to receive(:new).with(**geoip_settings).and_return(maxmind_client)
          expect(PhisherPhinder::CachedGeoipClient).to receive(:new).with(maxmind_client, now - 86400)

          subject.report(contents, **options.merge(geoip_lookup: true, geoip_settings: geoip_settings))
        end
      end
    end

    it 'initialises the ip factory' do
      expect(PhisherPhinder::ExtendedIpFactory).to receive(:new).with(geoip_client: null_client)

      subject.report(contents, **options)
    end

    it 'initialises the mail parser' do
      expect(PhisherPhinder::MailParser::Parser).to receive(:new).with(ip_factory, "\r\n")

      subject.report(contents, **options)
    end

    it 'parses the mail' do
      expect(mail_parser).to receive(:parse).with(contents)

      subject.report(contents, **options)
    end

    it 'intialises the Whois client' do
      expect(Whois::Client).to receive(:new)

      subject.report(contents, **options)
    end

    it 'initialises the email extractor' do
      expect(PhisherPhinder::WhoisEmailExtractor).to receive(:new)

      subject.report(contents, **options)
    end

    it 'initialises the HostInformationFinder' do
      expect(PhisherPhinder::HostInformationFinder).to receive(:new).
        with(whois_client: whois_client, extractor: extractor)

      subject.report(contents, **options)
    end

    it 'initialises the hyperlink explorer' do
      expect(PhisherPhinder::LinkExplorer).to receive(:new).with(
        host_information_finder: host_information_finder,
        host_response_policy: an_instance_of(PhisherPhinder::HostResponsePolicy)
      )

      subject.report(contents, **options)
    end

    it 'initialises the TraceReport' do
      expect(PhisherPhinder::TracingReport).to receive(:new).with(
        mail: mail, host_information_finder: host_information_finder, link_explorer: link_explorer
      )

      subject.report(contents, **options)
    end

    it 'returns the results of the traced report' do
      expect(subject.report(contents, **options)) .to eql report_output
    end
  end
end
