# frozen_string_literal: true

module PhisherPhinder
  module MailParser
    module AuthenticationHeaders
      class AuthResultsParser
        def initialize(ip_factory:)
          @ip_factory = ip_factory
        end

        def parse(value)
          output_template = {authserv_id: nil, auth: [], dkim: [], dmarc: [], iprev: [], spf: []}

          components(value).inject(output_template) do |output, component|
            component_type, parsed_component = parse_component(component)
            if output[component_type].respond_to?(:<<)
              output.merge(component_type => (output[component_type] << parsed_component))
            else
              output.merge(component_type => parsed_component)
            end
          end
        end

        private

        def components(value)
          value.split(';').map { |component| component.strip }
        end

        def parse_component(component)
          if component =~ /\Aspf=/
            [:spf, spf_data(component)]
          elsif component =~ /\Adkim=/
            [:dkim, dkim_data(component)]
          elsif component =~ /\Aiprev=/
            [:iprev, iprev_data(component)]
          elsif component =~ /\Aauth=/
            [:auth, auth_data(component)]
          elsif component =~ /\Admarc=/
            [:dmarc, {}]
          else
            [:authserv_id, component]
          end
        end

        def spf_data(value)
          patterns = [
            %r{
              spf=(?<result>[\S]+)\s
              \([^:]+:\s(?<ip>[\S]+)\sis\sneither\spermitted[^\)]+\)\s
              smtp.mailfrom=(?<from>[^\s;]+)
            }x,
            %r{
              spf=(?<result>[\S]+)\s
              \(.+\s(?<ip>[\S]+)\sas\spermitted.+\)\s
              smtp.mailfrom=(?<from>[^\s;]+)
            }x,
            %r{
              spf=(?<result>[\S]+)\ssmtp.mailfrom=(?<from>[^\s;]+)
            }x,
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || value.match(pattern)
          end

          if matches
            {
              result: matches[:result].to_sym,
              ip: matches.names.include?('ip') ? @ip_factory.build(matches[:ip]) : nil,
              from: matches[:from]
            }
          else
            {}
          end
        end

        def dkim_data(value)
          patterns = [
            %r{
              dkim=(?<result>[\S]+)\s.*?
              header.i=(?<identity>[\S]+)\s
              header.s=(?<selector>[\S]+)\s
              header.b=(?<hash_snippet>.{8})
            }x,
            %r{
              dkim=(?<result>[\S]+)\s.*?
              header.i=(?<identity>[\S]+)\s
              header.s=(?<selector>[\S]+)
            }x,
          ]

          matches = patterns.inject(nil) do |memo, pattern|
            memo || value.match(pattern)
          end

          if matches
            {
              result: matches[:result].to_sym,
              identity: matches[:identity],
              selector: matches[:selector],
              hash_snippet: extract(matches, :hash_snippet)
            }
          else
            {}
          end
        end

        def iprev_data(value)
          matches = value.match(
            /
            iprev=(?<result>[\S]+)\s
            \((?<remote_host_name>[^\)]+)\)\s
            smtp.remote-ip=(?<remote_ip>[^\s;]+)
            /x
          )

          if matches
            {
              result: matches[:result].to_sym,
              remote_host_name: matches[:remote_host_name],
              remote_ip: @ip_factory.build(matches[:remote_ip]),
            }
          else
            {}
          end
        end

        def auth_data(value)
          matches = value.match(/auth=(?<result>[\S]+)\s.+smtp.auth=(?<domain>[^\s;]+)/)

          if matches
            {
              result: matches[:result].to_sym,
              domain: matches[:domain],
            }
          else
            {}
          end
        end

        private

        def extract(matches, key)
          matches.names.include?(key.to_s) ? matches[key] : nil
        end
      end
    end
  end
end
