require 'request_helper'

RSpec.describe '/version' do
  let(:router) { Inferno::Web::Router }
  let(:response_field) { 'version' }
  let(:response_value) { Inferno::VERSION }

  describe '/version' do
    it 'renders the Inferno Core version as json' do
      get router.path(:api_version)

      expect(last_response.status).to eq(200)
      expect(parsed_body[response_field]).to eq(response_value)
    end
  end
end
