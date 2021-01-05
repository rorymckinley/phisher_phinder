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
          entry[:sender][:host],
          entry[:advertised_sender] || entry[:helo],
          entry[:recipient]
        ]
      end

      trace_table = Terminal::Table.new(
        headings: ['Sender IP', 'Sender Host', 'Advertised Sender', 'Recipient'],
        title: 'Trace',
        rows: data
      )

      puts trace_table
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
  end
end
