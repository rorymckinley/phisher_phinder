# frozen_string_literal: true
require 'uri'

RSpec.describe PhisherPhinder::BodyHyperlink do
  it 'indicates the type of link' do
    expect(described_class.new('https://foo/bar', '').type).to eql :url
    expect(described_class.new('https://foo/bar#baz', '').type).to eql :url
    expect(described_class.new('foobarbaz', '').type).to eql :url
    expect(described_class.new('#baz', '').type).to eql :url_fragment
    expect(described_class.new('  #baz  ', '').type).to eql :url_fragment
    expect(described_class.new('mailto:foo@b.com', '').type).to eql :email_address
    expect(described_class.new('  mailto:foo@b.com  ', '').type).to eql :email_address
    expect(described_class.new('tel:12345', '').type).to eql :telephone_number
    expect(described_class.new('  tel:12345  ', '').type).to eql :telephone_number
  end

  describe 'href' do
    it 'exposes the href for the hyperlink as a URI instance if it is a URL' do
      expect(described_class.new('https://foo/bar', '').href).to eql URI.parse('https://foo/bar')
      expect(described_class.new('  https://foo/bar  ', '').href).to eql URI.parse('https://foo/bar')
    end

    it 'does not attempt to parse an href if the link href is not url', :aggregate_failures do
      expect(described_class.new('#baz', '').href).to eql '#baz'
      expect(described_class.new('  #baz  ', '').href).to eql '#baz'
      expect(described_class.new('mailto:foo@b.com', '').href).to eql 'mailto:foo@b.com'
      expect(described_class.new('  mailto:foo@b.com  ', '').href).to eql 'mailto:foo@b.com'
      expect(described_class.new('tel:12345', '').href).to eql 'tel:12345'
      expect(described_class.new('  tel:12345  ', '').href).to eql 'tel:12345'
    end

    it 'does not attempt to parse en empty href' do
      expect(described_class.new('', '').href).to eql ''
    end
  end

  it 'exposes the text for the hyperlink' do
    expect(described_class.new('https://foo.bar', 'Foo Link').text).to eql 'Foo Link'
    expect(described_class.new('https://foo.bar', '  Foo Link  ').text).to eql '  Foo Link  '
  end

  it 'can deal with URLs that contain fragment identifiers' do
    expect(described_class.new('https://foo/bar##foo', '').href).to eql URI.parse('https://foo/bar')
    expect(described_class.new('https://foo/bar#[[Email]]', '').href).to eql URI.parse('https://foo/bar')
  end

  it 'stores the raw href that was passed in' do
    expect(described_class.new('https://foo/bar#[[Email]]', '').raw_href).to eql 'https://foo/bar#[[Email]]'
  end

  it 'considers two instances to be eql if they have the same href and link text' do
    expect(described_class.new('https://foo/bar', 'Foo')).to eq described_class.new('https://foo/bar', 'Foo')
    expect(described_class.new('https://notfoo/bar', 'Foo')).to_not eq described_class.new('https://foo/bar', 'Foo')
    expect(described_class.new('https://foo/bar', 'Foo')).to_not eq described_class.new('https://foo/bar', 'NotFoo')
  end

  it 'indicates if the link supports retrieval of contents' do
    expect(described_class.new('https://foo/bar', '').supports_retrieval?).to be_truthy
    expect(described_class.new('#baz', '').supports_retrieval?).to be_falsey
    expect(described_class.new('mailto:foo@b.com', '').supports_retrieval?).to be_falsey
    expect(described_class.new('tel:12345', '').supports_retrieval?).to be_falsey
    expect(described_class.new('', '').supports_retrieval?).to be_falsey
  end
end
