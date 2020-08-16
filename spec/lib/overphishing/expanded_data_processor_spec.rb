# frozen_string_literal: true
require 'spec_helper'
require 'uri'

RSpec.describe Overphishing::ExpandedDataProcessor do
  let(:html_body) do
    '<html><a href="http://foo">Foo</a><a href="http://bar">Bar</a><a href="http://baz">Baz</a>'
  end
  let(:mail) do
    Overphishing::Mail.new(
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
    it 'returns any content that can be fetched for the links' do
      result = subject.process(mail)

      expect(result[:linked_content]).to eql([
        {href: URI.parse('http://foo'), link_text: 'Foo', status: 200, body: 'Foo Body', links_within_body: []},
        {href: URI.parse('http://bar'), link_text: 'Bar', status: 404, body: nil, links_within_body: []},
        {href: URI.parse('http://baz'), link_text: 'Baz', status: 200, body: 'Baz Body', links_within_body: []},
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

      expect(result[:linked_content].first[:links_within_body]).to eql([
        'http://fizz', 'https://bar/baz'
      ])
    end
  end
end
