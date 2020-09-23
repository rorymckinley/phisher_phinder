# frozen_string_literal: true
require 'spec_helper'
require 'uri'

RSpec.describe PhisherPhinder::ExpandedDataProcessor do
  let(:html_body) do
    '<html>' +
      '<a href="http://foo">Foo</a>' +
      '<a href="tel:12345">Phone Me</a>' +
      '<a href="http://bar">Bar</a>' +
      '<a href="mailto:a@b.com">Mail</a>' +
      '<a href="http://baz">Baz</a>' +
      '<a href="#fragment">Frag</a>' +
      '<a href=""></a>' +
      '</html>'
  end
  let(:mail) do
    PhisherPhinder::Mail.new(
      original_email: '',
      original_headers: '',
      original_body: '',
      headers: '',
      tracing_headers: [],
      body: {html: html_body, text: ''}
    )
  end

  before(:each) do
    stub_request(:get, 'http://foo').to_return(body: 'Foo Body')
    stub_request(:get, 'http://bar').to_return(status: [404, 'Not Found'])
    stub_request(:get, 'http://baz').to_return(body: 'Baz Body')
  end

  it 'returns the mail as part of the response' do
    result = subject.process(mail)

    expect(result[:mail]).to eql mail
  end

  describe 'following the links in the body' do
    it 'returns any content that can be fetched for the links that have the url type' do
      result = subject.process(mail)

      expect(result[:linked_content]).to eql([
        {
          href: URI.parse('http://foo'),
          link_text: 'Foo',
          content_requested: true,
          error: nil,
          response: {
            status: 200,
            body: 'Foo Body',
            links_within_body: []
          }
        },
        {
          href: 'tel:12345',
          link_text: 'Phone Me',
          content_requested: false,
          error: nil,
          response: nil
        },
        {
          href: URI.parse('http://bar'),
          link_text: 'Bar',
          content_requested: true,
          error: nil,
          response: {
            status: 404,
            body: nil,
            links_within_body: []
          }
        },
        {
          href: 'mailto:a@b.com',
          link_text: 'Mail',
          content_requested: false,
          error: nil,
          response: nil,
        },
        {
          href: URI.parse('http://baz'),
          link_text: 'Baz',
          content_requested: true,
          error: nil,
          response: {
            status: 200,
            body: 'Baz Body',
            links_within_body: []
          }
        },
        {
          href: '#fragment',
          link_text: 'Frag',
          content_requested: false,
          error: nil,
          response: nil
        },
        {
          href: '',
          link_text: '',
          content_requested: false,
          error: nil,
          response: nil
        },
      ])
    end
  end

  describe 'extracting links from the fetched content' do
    let(:link_content) { 'Fizz http://fizz Bar https://bar/baz ' }
    before(:each) do
      stub_request(:get, 'http://foo').to_return(body: link_content)
    end

    it 'returns any urls that it can find in the content' do
      result = subject.process(mail)

      expect(result[:linked_content].first[:response][:links_within_body]).to eql([
        'http://fizz', 'https://bar/baz'
      ])
    end
  end

  describe 'fetching content raises an error' do
    let(:bar_response) do
      double(Net::HTTPOK, code: '200', body: 'Bar Body')
    end
    let(:html_body) do
      '<html>' +
        '<a href="http://foo">Foo</a>' +
        '<a href="http://baz">Baz</a>' +
        '<html>'
    end

    before(:each) do
      stub_request(:get, 'http://baz').to_return(body: 'Baz Body')
    end

    it 'tracks the error and continues processing the other links' do
      expect(Net::HTTP).to receive(:get_response).with(URI.parse('http://foo')).and_raise('Aaargh')
      expect(Net::HTTP).to receive(:get_response).with(URI.parse('http://baz')).and_call_original

      result = subject.process(mail)

      expect(result[:linked_content]).to eql([
        {
          href: URI.parse('http://foo'),
          link_text: 'Foo',
          content_requested: true,
          response: nil,
          error: {
            class: RuntimeError,
            message: 'Aaargh'
          }
        },
        {
          href: URI.parse('http://baz'),
          link_text: 'Baz',
          content_requested: true,
          response: {
            status: 200,
            body: 'Baz Body',
            links_within_body: []
          },
          error: nil,
        },
      ])
    end
  end
end
