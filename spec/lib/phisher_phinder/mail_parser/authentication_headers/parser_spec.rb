# frozen_string_literal:true

RSpec.describe PhisherPhinder::MailParser::AuthenticationHeaders::Parser do
  let(:auth_results_parser) do
    instance_double(PhisherPhinder::MailParser::AuthenticationHeaders::AuthResultsParser)
  end
  let(:received_spf_parser) do
    instance_double(PhisherPhinder::MailParser::AuthenticationHeaders::ReceivedSpfParser)
  end

  let(:headers) do
    {
      authentication_results: [
        {data: {auth: :one}, sequence: 1},
        {data: {auth: :two}, sequence: 2},
      ],
      received_spf: [
        {data: {spf: :one}, sequence: 3},
        {data: {spf: :two}, sequence: 4},
      ]
    }
  end

  subject do
    described_class.new(
      authentication_results_parser: auth_results_parser,
      received_spf_parser: received_spf_parser
    )
  end

  before(:each) do
    allow(auth_results_parser).to receive(:parse).with({auth: :one}).and_return({result: :one})
    allow(auth_results_parser).to receive(:parse).with({auth: :two}).and_return({result: :two})
    allow(received_spf_parser).to receive(:parse).with({spf: :one}).and_return({spf_result: :one})
    allow(received_spf_parser).to receive(:parse).with({spf: :two}).and_return({spf_result: :two})
  end

  describe 'authentication_results' do
    it 'passes the `Authentication Results` header data to the relevant parser' do
      allow(auth_results_parser).to receive(:parse).with({auth: :one}).and_return({result: :one})
      allow(auth_results_parser).to receive(:parse).with({auth: :two}).and_return({result: :two})

      expect(subject.parse(headers)[:authentication_results]).to eql([{result: :one}, {result: :two}])
    end

    it 'returns an empty array if there are no `Authentication Results` headers' do
      expect(subject.parse({})[:authentication_results]).to eql([])
    end
  end

  describe 'recived_spf' do
    it 'passes the `Received SPF` headers to the relevant parsers' do
      expect(received_spf_parser).to receive(:parse).with({spf: :one}).and_return({spf_result: :one})
      expect(received_spf_parser).to receive(:parse).with({spf: :two}).and_return({spf_result: :two})

      expect(subject.parse(headers)[:received_spf]).to eql([{spf_result: :one}, {spf_result: :two}])
    end

    it 'returns an empty array if there are no `Received SPF` entries' do
      expect(subject.parse({})[:received_spf]).to eql([])
    end
  end
end
