# frozen_string_literal: true

module PhisherPhinder
  class Command
    def report(contents, line_ending:, geoip_lookup:, geoip_settings: {})
      lookup_client = if geoip_lookup
                        PhisherPhinder::CachedGeoipClient.new(
                          MaxMind::GeoIP2::Client.new(**geoip_settings),
                          Time.now - 86400
                        )
                      else
                        PhisherPhinder::NullLookupClient.new
                      end
      ip_factory = PhisherPhinder::ExtendedIpFactory.new(geoip_client: lookup_client)
      mail_parser = PhisherPhinder::MailParser::Parser.new(ip_factory, line_ending)
      whois_client = Whois::Client.new
      host_information_finder = PhisherPhinder::HostInformationFinder.new(
        whois_client: whois_client,
        extractor: PhisherPhinder::WhoisEmailExtractor.new
      )
      tracing_report = PhisherPhinder::TracingReport.new(
        mail:  mail_parser.parse(contents),
        host_information_finder: host_information_finder,
        link_explorer: PhisherPhinder::LinkExplorer.new(
          host_information_finder: host_information_finder,
          host_response_policy: PhisherPhinder::HostResponsePolicy.new
        )
      )
      tracing_report.report
    end
  end
end
