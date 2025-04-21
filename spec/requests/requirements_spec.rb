require 'request_helper'

RSpec.describe '/requirements' do
  let(:router) { Inferno::Web::Router }
  let(:repo) { Inferno::Repositories::Requirements.new }
  let(:fields) { ['id', 'requirement', 'conformance', 'actor', 'conditionality', 'sub_requirements'] }
  let(:requirement_id) { 'sample-criteria-proposal@4' }

  describe 'show' do
    context 'when the requirement does not exist' do
      it 'renders a 404' do
        get router.path(:api_requirements_show, id: 'test3o4')

        expect(last_response.status).to eq(404)
      end
    end

    context 'when the requirement exist' do
      it 'renders a requirement json' do
        get router.path(:api_requirements_show, id: requirement_id)
        expect(last_response.status).to eq(200)
        expect(parsed_body['id']).to eq(requirement_id)
        expect(parsed_body).to include(*fields)
      end
    end
  end
end
