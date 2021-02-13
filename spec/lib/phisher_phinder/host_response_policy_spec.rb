# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::HostResponsePolicy do
  let(:populated_headers) { {'Location' => 'http://foo.bar'} }
  let(:headers_empty_location) { {'Location' => ''} }
  let(:headers_no_location) { {} }
  let(:headers_relative_location) { {'Location' => '/relative/path'} }
  let(:url) { URI.parse('https://baz.bar') }

  describe '#next_host_url' do
    describe '2xx status codes' do
      let(:response_200) { instance_double(Excon::Response, status: 200, headers: headers_no_location) }
      let(:response_226) { instance_double(Excon::Response, status: 226, headers: headers_no_location) }

      it 'returns nil' do
        expect(subject.next_url(url, response_200)).to be_nil
        expect(subject.next_url(url, response_226)).to be_nil
      end
    end

    describe '4xx status codes' do
      let(:response_400) { instance_double(Excon::Response, status: 400, headers: headers_no_location) }
      let(:response_451) { instance_double(Excon::Response, status: 451, headers: headers_no_location) }

      it 'returns nil' do
        expect(subject.next_url(url, response_400)).to be_nil
        expect(subject.next_url(url, response_451)).to be_nil
      end
    end

    describe '5xx status codes' do
      let(:response_500) { instance_double(Excon::Response, status: 500, headers: headers_no_location) }
      let(:response_511) { instance_double(Excon::Response, status: 511, headers: headers_no_location) }

      it 'returns nil for responses with a 5xx status code' do
        expect(subject.next_url(url, response_500)).to be_nil
        expect(subject.next_url(url, response_511)).to be_nil
      end
    end

    describe '301, 302, 303, 307, 308 codes' do
      let(:response_301) { instance_double(Excon::Response, status: 301, headers: headers) }
      let(:response_302) { instance_double(Excon::Response, status: 302, headers: headers) }
      let(:response_303) { instance_double(Excon::Response, status: 303, headers: headers) }
      let(:response_307) { instance_double(Excon::Response, status: 307, headers: headers) }
      let(:response_308) { instance_double(Excon::Response, status: 308, headers: headers) }

      describe 'with a populated Location header' do
        let(:headers) { populated_headers }

        it 'returns a URL for responses with a 301, 302, 303, 307, 308 with a `Location` header' do
          expect(subject.next_url(url, response_301)).to eql URI.parse('http://foo.bar')
          expect(subject.next_url(url, response_302)).to eql URI.parse('http://foo.bar')
          expect(subject.next_url(url, response_303)).to eql URI.parse('http://foo.bar')
          expect(subject.next_url(url, response_307)).to eql URI.parse('http://foo.bar')
          expect(subject.next_url(url, response_308)).to eql URI.parse('http://foo.bar')
        end
      end

      describe 'with an empty Location header' do
        let(:headers) { headers_empty_location }

        it 'returns nil' do
          expect(subject.next_url(url, response_301)).to be_nil
          expect(subject.next_url(url, response_302)).to be_nil
          expect(subject.next_url(url, response_303)).to be_nil
          expect(subject.next_url(url, response_307)).to be_nil
          expect(subject.next_url(url, response_308)).to be_nil
        end
      end

      describe 'without a Location header' do
        let(:headers) { headers_no_location }

        it 'returns nil' do
          expect(subject.next_url(url, response_301)).to be_nil
          expect(subject.next_url(url, response_302)).to be_nil
          expect(subject.next_url(url, response_303)).to be_nil
          expect(subject.next_url(url, response_307)).to be_nil
          expect(subject.next_url(url, response_308)).to be_nil
        end
      end

      describe 'with a Location header that points to a relative path' do
        let(:headers) { headers_relative_location }

        it 'returns an absolute url' do
          expect(subject.next_url(url, response_301)).to eql URI.parse('https://baz.bar/relative/path')
          expect(subject.next_url(url, response_302)).to eql URI.parse('https://baz.bar/relative/path')
          expect(subject.next_url(url, response_303)).to eql URI.parse('https://baz.bar/relative/path')
          expect(subject.next_url(url, response_307)).to eql URI.parse('https://baz.bar/relative/path')
          expect(subject.next_url(url, response_308)).to eql URI.parse('https://baz.bar/relative/path')
        end
      end
    end

    describe '304, 305, 306 codes' do
      let(:response_304) { instance_double(Excon::Response, status: 304, headers: populated_headers) }
      let(:response_305) { instance_double(Excon::Response, status: 305, headers: populated_headers) }
      let(:response_306) { instance_double(Excon::Response, status: 306, headers: populated_headers) }

      it 'returns nil for responses with a 304, 305, 306 response code' do
        expect(subject.next_url(url, response_304)).to be_nil
        expect(subject.next_url(url, response_305)).to be_nil
        expect(subject.next_url(url, response_306)).to be_nil
      end
    end
  end
end
