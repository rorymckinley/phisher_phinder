require "phisher_phinder/version"

require 'maxmind/geoip2'

require 'sequel'
Sequel::Model.plugin :timestamps, update_on_create: true

require_relative './phisher_phinder/body_hyperlink'
require_relative './phisher_phinder/cached_geoip_client'
require_relative './phisher_phinder/geoip_ip_data'
require_relative './phisher_phinder/expanded_data_processor'
require_relative './phisher_phinder/extended_ip'
require_relative './phisher_phinder/extended_ip_factory'
require_relative './phisher_phinder/mail_parser'
require_relative './phisher_phinder/mail'
require_relative './phisher_phinder/simple_ip'
require_relative './phisher_phinder/mail_parser/authentication_headers/parser'
require_relative './phisher_phinder/mail_parser/authentication_headers/auth_results_parser'
require_relative './phisher_phinder/mail_parser/authentication_headers/received_spf_parser'
require_relative './phisher_phinder/mail_parser/body/block_classifier'
require_relative './phisher_phinder/mail_parser/body/block_parser'
require_relative './phisher_phinder/mail_parser/received_headers/parser'
require_relative './phisher_phinder/mail_parser/received_headers/by_parser'
require_relative './phisher_phinder/mail_parser/received_headers/classifier'
require_relative './phisher_phinder/mail_parser/received_headers/for_parser'
require_relative './phisher_phinder/mail_parser/received_headers/from_parser'
require_relative './phisher_phinder/mail_parser/received_headers/starttls_parser'
require_relative './phisher_phinder/mail_parser/received_headers/timestamp_parser'
require_relative './phisher_phinder/sender_extractor'
require_relative './phisher_phinder/tracing_report'

module PhisherPhinder
  class Error < StandardError; end
  # Your code goes here...
end
