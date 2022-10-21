require 'request_helper'

RSpec.describe '/requests/:id' do
  let(:router) { Inferno::Web::Router }
  let(:response_fields) { ['id', 'inputs', 'results', 'status', 'test_group_id'] }
  let(:test_group_id) { BasicTestSuite::Suite.groups.first.id }
  let(:test_run) { repo_create(:test_run, runnable: { test_group_id: }) }
  let(:result) { repo_create(:result, test_run:) }
  let(:request) { repo_create(:request, result:) }

  describe '/requests/:id' do
    it 'renders the full json for a request' do
      get router.path(:api_requests_show, id: request.id)

      expect(last_response.status).to eq(200)

      values_to_validate = request.to_hash.slice(
        :verb, :url, :direction, :status, :request_body, :response_body, :result_id
      )

      values_to_validate.each do |key, value|
        expect(parsed_body[key.to_s]).to eq(value)
      end

      request_header = parsed_body['request_headers'].first
      persisted_header = request.request_headers.first
      expect(request_header['name']).to eq(persisted_header.name)
      expect(request_header['value']).to eq(persisted_header.value)

      response_header = parsed_body['response_headers'].first
      persisted_header = request.response_headers.first
      expect(response_header['name']).to eq(persisted_header.name)
      expect(response_header['value']).to eq(persisted_header.value)
    end
  end
end
