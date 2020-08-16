# frozen_string_literal: true
require 'uri'

RSpec.describe Overphishing::BodyHyperlink do
  it 'exposes the href for the hyperlink' do
    expect(described_class.new('https://foo/bar', '').href).to eql URI.parse('https://foo/bar')
  end

  it 'exposes the text for the hyperlink' do
    expect(described_class.new('', 'Foo Link').text).to eql 'Foo Link'
  end

  it 'removes characters from the hyperlink that cannot be aprsed as part of the URI' do
    expect(described_class.new('https://foo/bar##foo', '').href).to eql URI.parse('https://foo/bar')
  end

  it 'considers two instances to be eql if they have the same href and link text' do
    expect(described_class.new('https://foo/bar', 'Foo')).to eq described_class.new('https://foo/bar', 'Foo')
    expect(described_class.new('https://notfoo/bar', 'Foo')).to_not eq described_class.new('https://foo/bar', 'Foo')
    expect(described_class.new('https://foo/bar', 'Foo')).to_not eq described_class.new('https://foo/bar', 'NotFoo')
  end
end
