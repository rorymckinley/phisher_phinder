# frozen_string_literal: true

module Overphishing
  class MailParser
    def initialize(enriched_ip_factory, line_ending_type)
      @line_end = line_ending_type == 'dos' ? "\r\n" : "\n"
      @enriched_ip_factory = enriched_ip_factory
    end

    def parse(contents)
      headers, body = separate(contents)
      Mail.new(
        original_email: contents,
        original_headers: headers,
        original_body: body,
        headers: extract_headers(headers),
        tracing_headers: generate_tracing_headers(extract_headers(headers))
      )
    end

    private

    def separate(contents)
      contents.split("#{@line_end}#{@line_end}")
    end

    def extract_headers(headers)
      parse_headers(unfold_headers(headers).split(@line_end))
    end

    def unfold_headers(headers)
      headers.gsub(/#{@line_end}[\s\t]+/, ' ')
    end

    def parse_headers(headers_array)
      headers_array.each_with_index.inject({}) do |memo, (header_string, index)|
        header, value = header_string.split(":", 2)
        sequence = headers_array.length - index - 1
        memo.merge(convert_header_name(header) => enrich_header_value(value, sequence)) do |_, existing, new|
          if existing.is_a? Array
            existing << new
          else
            [existing, new]
          end
        end
      end
    end

    def convert_header_name(header)
      header.gsub(/-/, '_').downcase.to_sym
    end

    def enrich_header_value(value, sequence)
      {data: value.strip, sequence: sequence}
    end

    def generate_tracing_headers(headers)
      received_header_values = headers.inject([]) do |memo, (header_name, header_value)|
        if [:received, :x_received].include? header_name
          if header_value.is_a? Array
            memo +=  header_value
          else
            memo << header_value
          end
        end

        memo
      end.flatten

      {
        received: restore_sequence(received_header_values).map { |v| parse_received_header(v[:data]) }
      }
    end

    def parse_received_header(value)
      data, timestamp = value.split(';')

      time = parse_received_timestamp(timestamp) if timestamp
      parse_received_data(data).merge(time: time)
    end

    def parse_received_data(data)
      require 'strscan'

      scanner = StringScanner.new(data)

      if scanner.check(/\(from\s+[^)]+\)/)
        from_part = scanner.scan(/\(from\s+[^)]+\)/)
      else
        from_part = scanner.scan(/from\s.+?\([^)]+?\)/)
      end
      by_part = scanner.scan(/\s?by.+?id\s[\S]+\s?/) unless scanner.eos?
      for_part = scanner.scan(/for\s+\S+/) unless scanner.eos?
      starttls_part = scanner.rest unless scanner.eos?

      base = {
        advertised_sender: nil,
        id: nil,
        partial: true,
        protocol: nil,
        recipient: nil,
        recipient_additional: nil,
        recipient_mailbox: nil,
        sender: nil,
        starttls: nil,
        time: nil
      }

      if from_part
        patterns = [
          /from\s(?<advertised_sender>[\S]+)\s\((?<sender_host>\S+?)\.?\s\[(?<sender_ip>[^\]]+)\]\)/,
          /from\s(?<advertised_sender>\S+)\s\((?<sender_host>\S+?)\.?\s(?<sender_ip>\S+?)\)/,
          /from\s(?<advertised_sender>\S+)\s\(\[(?<sender_ip>[^\]]+)\]\)/,
          /\(from\s(?<advertised_sender>[^)]+)\)/
        ]

        matches = patterns.inject(nil) do |memo, pattern|
          memo || from_part.match(pattern)
        end

        base.merge!(
          advertised_sender: matches[:advertised_sender],
          sender: {
            host: matches.names.include?('sender_host') ? matches[:sender_host] : nil,
            ip: matches.names.include?('sender_ip') ? @enriched_ip_factory.build(matches[:sender_ip]) : nil
          }
        )
      end

      if by_part
        patterns = [
          /by\s(?<recipient>\S+)\swith\s(?<protocol>\S+)\sid\s(?<id>\S+)/,
          /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\swith\s(?<protocol>\S+)\sid\s(?<id>\S+)/,
          /by\s(?<recipient>\S+)\s\((?<additional>[^)]+)\)\sid\s(?<id>\S+)/
        ]

        matches = patterns.inject(nil) do |memo, pattern|
          memo || by_part.match(pattern)
        end

        base.merge!(
          recipient: enrich_recipient(matches[:recipient]),
          protocol: matches.names.include?('protocol') ? matches[:protocol]: nil,
          id: matches[:id],
          recipient_additional: matches.names.include?('additional') ? matches[:additional] : nil
        )
      end

      if for_part
        for_part =~ /\Afor\s(\S+)\z/

        base.merge!(recipient_mailbox: strip_angle_brackets($1))
      end

      if starttls_part
        matches = starttls_part.match(/\(version=(?<version>\S+)\scipher=(?<cipher>\S+)\sbits=(?<bits>\S+)\)/)

        require 'pry'
        binding.pry unless matches
        base.merge!(starttls: {version: matches[:version], cipher: matches[:cipher], bits: matches[:bits]})
      end

      base.merge!(partial: !(from_part && by_part && for_part && (base[:protocol] != 'ESMPTS' || (base[:protocol] == 'ESMTPS' && starttls_part)) && true))

      base
    end

    def parse_received_timestamp(timestamp)
      require 'time'

      Time.strptime(timestamp.strip, "%a, %d %b %Y %H:%M:%S %z (%Z)")
    rescue ArgumentError
      Time.strptime(timestamp.strip, "%a, %d %b %Y %H:%M:%S %z")
    end

    def restore_sequence(values)
      values.sort { |a,b| b[:sequence] <=> a[:sequence] }
    end

    def strip_angle_brackets(email_address_string)
      email_address_string =~ /\<([^>]+)\>/ ? $1 : email_address_string
    end

    def enrich_recipient(recipient)
      @enriched_ip_factory.build(recipient) || recipient
    end

    def is_ip?(data)
      data =~ Resolv::IPv6::Regex || data =~ Resolv::IPv4::Regex
    end
  end
end
