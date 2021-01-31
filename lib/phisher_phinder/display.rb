# frozen_string_literal: true
require 'terminal-table'

module PhisherPhinder
  class Display
    def display_report(input_data)
      origin_table = Terminal::Table.new(
        title: 'Origin',
        rows: format_origin_data(input_data)
      )

      puts origin_table

      puts "\n\n"

      spf_table = Terminal::Table.new(
        headings: ['SPF Pass?', 'Sender Host', 'From Address'],
        title: 'SPF',
        rows: [
          [
            input_data[:authentication][:spf][:success] ? 'Yes' : 'No',
            input_data[:authentication][:spf][:ip],
            input_data[:authentication][:spf][:from_address]
          ]
        ]
      )

      puts spf_table

      puts "\n\n"

      data = input_data[:tracing].map do |entry|
        [
          entry[:sender][:ip],
          display_email_addresses(entry[:sender_contact_details][:ip][:email]),
          entry[:sender][:host],
          display_email_addresses(entry[:sender_contact_details][:host][:email]),
          entry[:advertised_sender] || entry[:helo],
          entry[:recipient]
        ]
      end

      trace_table = Terminal::Table.new(
        headings: ['Sender IP', 'IP Contacts', 'Sender Host', 'Host Contacts', 'Advertised Sender', 'Recipient'],
        title: 'Trace',
        rows: data
      )

      puts trace_table

      puts "\n\n"

      puts 'Body Content'
      puts "\n"
      puts "Linked URLs"
      input_data[:content][:linked_urls].each do |link_set|
        link_set.each_with_index do |link_host, tab_count|
          puts "#{"\t"*tab_count}" +
            "#{link_host.url.to_s} " +
            "(#{display_creation_date(link_host)}) " +
            "[#{display_email_addresses(link_host.host_information[:abuse_contacts])}]" +
            "\n"
        end
        puts "\n"
      end
    end

    private

    def format_origin_data(input_data)
      types = [
        ['From', :from],
        ['Message ID', :message_id],
        ['Return Path', :return_path],
      ]

      types.inject([]) do |output, (description, type)|
        output << [description, input_data[:origin][type].join(', ')]
      end
    end

    def display_email_addresses(email_addresses)
      email_addresses.map { |address| address.gsub(/[,<>]/, '') }.join(', ')
    end

    def display_creation_date(link_host)
      (date = link_host.host_information[:creation_date]) ? date.strftime('%Y-%m-%d %H:%M:%S') : nil
    end
  end
end
