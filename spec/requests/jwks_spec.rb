require 'request_helper'

RSpec.describe '/jwks.json' do
  let(:router) { Inferno::Web::Router }
  let(:parsed_response) { JSON.parse(Inferno::JWKS.jwks_json) }

  describe '/jwks.json' do
    it 'renders the Inferno Core JWKS as json' do
      get router.path(:jwks)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eq(parsed_response)
    end
  end
end
