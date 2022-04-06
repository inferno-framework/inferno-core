RSpec.describe Inferno::Entities::Request do
  describe '.from_http_request' do
    let(:url) { 'http://example.com/' }
    let(:request_body) { 'REQUEST_BODY' }
    let(:response_body) { { ABC: 'DEF' }.to_json }
    let(:request_headers) { { Accept: 'application/json' } }
    let(:response_headers) { { 'Content-Type': 'application/json' } }

    it 'builds a Request from a Faraday response' do
      stub_request(:post, url)
        .to_return(status: 200, body: response_body, headers: response_headers)

      response = Faraday.new(url: url).post('', request_body, request_headers)

      entity = described_class.from_http_response(response, name: 'NAME', test_session_id: nil)

      expect(entity.verb).to eq(:post)
      expect(entity.url).to eq(url)
      expect(entity.direction).to eq('outgoing')
      expect(entity.name).to eq(:NAME)
      expect(entity.status).to eq(200)
      expect(entity.request_body).to eq(request_body)
      expect(entity.response_body).to eq(response_body)
      expect(
        entity.request_headers.one? { |header| header.name == 'accept' && header.value == 'application/json' }
      ).to be(true)
      expect(
        entity.response_headers.one? { |header| header.name == 'content-type' && header.value == 'application/json' }
      ).to be(true)
    end
  end

  describe '.from_fhir_client_reply' do
    let(:url) { 'http://example.com/Patient' }
    let(:request_body) { FHIR::Patient.new }
    let(:response_body) { FHIR::OperationOutcome.new }
    let(:response_headers) { { 'Content-Type': 'application/fhir+json' } }

    it 'builds a Request from a FHIR::ClientReply' do
      stub_request(:post, url)
        .to_return(status: 200, body: response_body.to_json, headers: response_headers)

      response = FHIR::Client.new('http://example.com').create(request_body)

      entity = described_class.from_fhir_client_reply(response, name: 'NAME', test_session_id: nil)

      expect(entity.verb).to eq(:post)
      expect(entity.url).to eq(url)
      expect(entity.direction).to eq('outgoing')
      expect(entity.name).to eq(:NAME)
      expect(entity.status).to eq(200)
      expect(entity.request_body).to eq(request_body.to_json)
      expect(entity.response_body).to eq(response_body.to_json)
      expect(
        entity.request_headers.one? { |header| header.name == 'accept' && header.value == 'application/fhir+json' }
      ).to be(true)
      expect(
        entity.response_headers.one? do |header|
          header.name == 'content-type' && header.value == 'application/fhir+json'
        end
      ).to be(true)
    end

    it 'correctly handles form encoded bodies' do
      params = { _id: 'ABC' }
      stub_request(:post, "#{url}/_search")
        .to_return(status: 200)

      response = FHIR::Client.new('http://example.com').search(FHIR::Patient, search: { body: params })

      entity = described_class.from_fhir_client_reply(response, test_session_id: nil)

      expect(entity.request_body).to eq(URI.encode_www_form(params))
    end
  end
end
