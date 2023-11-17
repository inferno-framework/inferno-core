require_relative '../../../lib/inferno/repositories/requests'

RSpec.describe Inferno::Repositories::Requests do
  let(:repo) { described_class.new }
  let(:test_run) { repo_create(:test_run) }
  let(:result) { repo_create(:result, test_run:) }
  let(:test_session) { test_run.test_session }
  let(:request_params) do
    {
      verb: 'get',
      url: 'http://example.com',
      direction: 'outgoing',
      status: 200,
      request_body: 'REQUEST_BODY',
      response_body: 'RESPONSE_BODY',
      result_id: result.id,
      test_session_id: test_session.id,
      request_headers: [{ name: 'REQUEST_HEADER_NAME', value: 'REQUEST_HEADER_VALUE', type: 'request' }],
      response_headers: [{ name: 'RESPONSE_HEADER_NAME', value: 'RESPONSE_HEADER_VALUE', type: 'response' }],
      tags: ['abc', 'def']
    }
  end

  describe '#create' do
    it 'persists a request' do
      request = repo.create(request_params)

      request_params.each do |field, value|
        next if [:request_headers, :response_headers].include?(field)

        expect(request.send(field)).to eq(value)
      end

      request_header = request.request_headers.first
      response_header = request.response_headers.first

      expect(request.id).to be_present
      expect(request.index).to be_present
      expect(request.created_at).to be_present
      expect(request.updated_at).to be_present
      expect(request_header.name).to eq('REQUEST_HEADER_NAME')
      expect(request_header.value).to eq('REQUEST_HEADER_VALUE')
      expect(response_header.name).to eq('RESPONSE_HEADER_NAME')
      expect(response_header.value).to eq('RESPONSE_HEADER_VALUE')
    end
  end

  describe '#find' do
    let(:persisted_request) { repo_create(:request) }

    it 'returns a request summary' do
      request = repo.find(persisted_request.id)

      summary_fields = Inferno::Entities::Request::SUMMARY_FIELDS.dup
      [:id, :index, :created_at, :updated_at].each { |field| summary_fields.delete(field) }

      summary_fields.each do |field|
        next if [:id, :index].include?(field)

        expect(request.send(field)).to eq(persisted_request.send(field))
      end

      expect(request.request_body).to be_blank
      expect(request.response_body).to be_blank
      expect(request.headers).to be_blank
    end
  end

  describe '#find_full_request' do
    let(:persisted_request) { repo_create(:request, request_params) }

    it 'returns a complete request' do
      request = repo.find_full_request(persisted_request.id)

      summary_fields = Inferno::Entities::Request::SUMMARY_FIELDS.dup
      [:id, :index, :created_at, :updated_at].each { |field| summary_fields.delete(field) }

      summary_fields.each do |field|
        next if [:id, :index].include?(field)

        expect(request.send(field)).to eq(persisted_request.send(field))
      end

      expect(request.request_body).to eq(persisted_request.request_body)
      expect(request.response_body).to eq(persisted_request.response_body)
      expect(request.headers.length).to eq(persisted_request.headers.length)
      expect(request.request_headers.length).to eq(persisted_request.request_headers.length)
      expect(request.response_headers.length).to eq(persisted_request.response_headers.length)
      expect(request.tags).to be_present
      expect(request.tags).to match_array(persisted_request.tags)
    end
  end

  describe '#requests_for_result' do
    let!(:persisted_requests) { repo_create_list(:request, 2, result_id: result.id) }

    it 'returns request summaries for a result' do
      requests = repo.requests_for_result(result.id)

      summary_fields = Inferno::Entities::Request::SUMMARY_FIELDS.dup
      [:id, :index, :created_at, :updated_at].each { |field| summary_fields.delete(field) }

      expect(requests.length).to eq(persisted_requests.length)

      requests.each_with_index do |request, i|
        summary_fields.each do |field|
          next if [:id, :index].include?(field)

          expect(request.send(field)).to eq(persisted_requests[i].send(field))
        end

        expect(request.request_body).to be_blank
        expect(request.response_body).to be_blank
        expect(request.headers).to be_blank
      end
    end
  end

  describe '#find_named_request' do
    it 'returns the most recent request with the given name for the test session' do
      5.times do |i|
        url = "http://example.com/#{i}"
        repo_create(:request, url:, result_id: result.id, test_session_id: test_session.id, name: 'NAME')
      end

      request = repo.find_named_request(test_session.id, :NAME)

      expect(request.url).to eq('http://example.com/4')
      expect(request.headers).to be_present
    end
  end
end
