# frozen_string_literal: true

RSpec.describe PhisherPhinder::LinkExplorer do
  describe '#explore' do

    subject do
      described_class.new(
        host_information_finder: host_information_finder,
        host_response_policy: PhisherPhinder::HostResponsePolicy.new,
      )
    end

    describe 'mail hyperlink href points to url' do
      let(:headers_0) do
        {
          'Location' => url_1,
          'X-Arb' => 'Host-0',
        }
      end
      let(:headers_1) do
        {
          'Location' => url_2,
          'X-Arb' => 'Host-1',
        }
      end
      let(:headers_2) do
        {
          'X-Arb' => 'Host-2',
        }
      end
      let(:host_information_0) { {info: :host_0} }
      let(:host_information_1) { {info: :host_1} }
      let(:host_information_2) { {info: :host_2} }
      let(:host_information_finder) do
        instance_double(PhisherPhinder::HostInformationFinder).tap do |finder|
          allow(finder).to receive(:information_for).with('https://foo.bar').and_return(host_information_0)
          allow(finder).to receive(:information_for).with('https://biz.bar').and_return(host_information_1)
          allow(finder).to receive(:information_for).with('https://boz.bar').and_return(host_information_2)
        end
      end
      let(:url_0) { 'https://foo.bar/buzz?biz=boz' }
      let(:url_1) { 'https://biz.bar/foo?bar=biz' }
      let(:url_2) { 'https://boz.bar/buzz?bur=baz' }
      let(:root_link) { PhisherPhinder::BodyHyperlink.new(url_0, '') }

      before(:each) do
        stub_request(:get, url_0).
          to_return(
            body: 'Foo Bar Body',
            status: [301, 'Moved Permanently'],
            headers: headers_0,
          )
        stub_request(:get, url_1).
          to_return(
            body: 'Biz Bar Body',
            status: [301, 'Moved Permanently'],
            headers: headers_1
          )
      end

      it 'requests extended information for each host' do
        stub_request(:get, url_2).
          to_return(
            status: [200, 'OK'],
          )

        expect(host_information_finder).to receive(:information_for).with('https://foo.bar')
        expect(host_information_finder).to receive(:information_for).with('https://biz.bar')
        expect(host_information_finder).to receive(:information_for).with('https://boz.bar')

        subject.explore(root_link)
      end

      it 'follows a chain of links a host responds with 2xx and returns that chain' do
        stub_request(:get,  url_2).
          to_return(
            body: 'Boz Bar Body',
            status: [200, 'OK'],
            headers: headers_2
          )

        expect(subject.explore(root_link)).to eq([
          PhisherPhinder::LinkHost.new(
            url: URI.parse(url_0),
            body: 'Foo Bar Body',
            status_code: 301,
            headers: headers_0,
            host_information: host_information_0,
          ),
          PhisherPhinder::LinkHost.new(
            url: URI.parse(url_1),
            body: 'Biz Bar Body',
            status_code: 301,
            headers: headers_1,
            host_information: host_information_1,
          ),
          PhisherPhinder::LinkHost.new(
            url: URI.parse(url_2),
            body: 'Boz Bar Body',
            status_code: 200,
            headers: headers_2,
            host_information: host_information_2,
          ),
        ])
      end
    end
  end
end
