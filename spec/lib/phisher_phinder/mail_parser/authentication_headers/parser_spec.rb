# frozen_string_literal:true

RSpec.describe PhisherPhinder::MailParser::AuthenticationHeaders::Parser do
  let(:auth_results_parser) do
    parser = instance_double(PhisherPhinder::MailParser::AuthenticationHeaders::AuthResultsParser)
    allow(parser).to receive(:parse).with({auth: :one}).and_return({result: :one})
    allow(parser).to receive(:parse).with({auth: :two}).and_return({result: :two})
    parser
  end

  let(:headers) do
    {
      authentication_results: [
        {data: {auth: :one}, sequence: 1},
        {data: {auth: :two}, sequence: 2},
      ]
    }
  end

  subject { described_class.new(authentication_results_parser: auth_results_parser) }

  it 'passes the `Authentication Results` header data to the relevant parser' do
    expect(subject.parse(headers)).to eql({authentication_results: [{result: :one}, {result: :two}]})
  end

  it 'returns an empty array if there are no `Authentication Results` headers' do
    expect(subject.parse({})).to eql({authentication_results: []})
  end
end
