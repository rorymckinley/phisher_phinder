# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::Mail do
  let(:base_headers) do
    {
      original_email: '',
      original_headers: '',
      original_body: '',
      headers: {},
      tracing_headers: [],
      body: ''
    }
  end

  it 'exposes all the email addresses that appear in the Reply-To headers' do
    mail = described_class.new(
      **base_headers.merge({
        headers: {
          reply_to: [
            "a@b.com",
            "c@d.com, <d@e.com >",
            "d@e.com, e@F.com",
            "G <g@h.com>, H <h@i.com>"
          ]
        }
      })
    )

    expect(mail.reply_to_addresses.sort).to eql([
      'a@b.com', 'c@d.com', 'd@e.com', 'e@f.com', 'g@h.com', 'h@i.com'
    ])
  end

  it 'returns a collection of hypertext_links found in the mail body' do
    html_body = '<html> <a href="http://foo">Click Me!</a> <a href="http://bar">No, click me!</a> </html>'
    mail = described_class.new(**base_headers.merge(body: {html: html_body, text: 'Foo'}))

    expect(mail.hypertext_links.length).to eql 2
    expect(mail.hypertext_links.first).to eq PhisherPhinder::BodyHyperlink.new('http://foo', 'Click Me!')
    expect(mail.hypertext_links.last).to eq PhisherPhinder::BodyHyperlink.new('http://bar', 'No, click me!')
  end

  it 'ignores hyperlinks that do not have an href' do
    html_body = '<html> <a href="http://foo">Click Me!</a> <a></a> <a href="http://bar">No, click me!</a> </html>'
    mail = described_class.new(**base_headers.merge(body: {html: html_body, text: 'Foo'}))

    expect(mail.hypertext_links.length).to eql 2
    expect(mail.hypertext_links.first).to eq PhisherPhinder::BodyHyperlink.new('http://foo', 'Click Me!')
    expect(mail.hypertext_links.last).to eq PhisherPhinder::BodyHyperlink.new('http://bar', 'No, click me!')
  end

  it 'returns an empty collection if there is no content that is classified as HTML' do
    mail = described_class.new(**base_headers.merge(body: {html: nil, text: 'Foo'}))

    expect(mail.hypertext_links).to eql []
  end
end
