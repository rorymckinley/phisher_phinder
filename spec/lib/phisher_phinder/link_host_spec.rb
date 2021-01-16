# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::LinkHost do
  subject do
    described_class.new(
      url: URI.parse('http://a.b'),
      body: 'foo',
      status_code: 200,
      headers: {foo: :bar},
      host_information: {host: :information},
    )
  end
  it 'is equal to another instance if they have the same url, body, response_code and headers' do
    expect(subject).to eq(
      described_class.new(
        url: URI.parse('http://a.b'),
        body: 'foo',
        status_code: 200,
        headers: {foo: :bar},
        host_information: {host: :information},
      )
    )

    expect(subject).to_not eq(
      described_class.new(
        url: URI.parse('http://a.c'),
        body: 'foo',
        status_code: 200,
        headers: {foo: :bar},
        host_information: {host: :information},
      )
    )

    expect(subject).to_not eq(
      described_class.new(
        url: URI.parse('http://a.b'),
        body: 'foe',
        status_code: 200,
        headers: {foo: :bar},
        host_information: {host: :information},
      )
    )

    expect(subject).to_not eq(
      described_class.new(
        url: URI.parse('http://a.b'),
        body: 'foo',
        status_code: 201,
        headers: {foo: :bar},
        host_information: {host: :information},
      )
    )

    expect(subject).to_not eq(
      described_class.new(
        url: URI.parse('http://a.b'),
        body: 'foo',
        status_code: 200,
        headers: {foo: :bir},
        host_information: {host: :information},
      )
    )

    expect(subject).to_not eq(
      described_class.new(
        url: URI.parse('http://a.b'),
        body: 'foo',
        status_code: 200,
        headers: {foo: :bar},
        host_information: {host: :other_information},
      )
    )
  end
end
