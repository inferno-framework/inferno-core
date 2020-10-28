require 'request_helper'

RSpec.describe '/test_suites' do
  let(:router) { Inferno::Web::Router }
  let(:repo) { Inferno::Repositories::TestSuites.new }
  let(:summary_fields) { ['id', 'title'] }
  let(:full_fields) { ['test_groups'] }
  let(:all_fields) { summary_fields.concat(full_fields) }

  describe 'index' do
    let(:index_path) { router.path(:api_test_suites) }

    it 'renders json of test_suite summaries' do
      get index_path

      expect(last_response.status).to eq(200)

      test_suites = parsed_body

      expect(test_suites.length).to eq(repo.all.length)
      expect(test_suites).to all(include(*summary_fields))
      expect(test_suites).to all(exclude(*full_fields))
    end
  end

  describe 'show' do
    context 'when the test_suite exists' do
      let(:test_suite_id) { repo.all.first.id }

      it 'renders the test_suite json' do
        get router.path(:api_test_suite, id: test_suite_id)

        expect(last_response.status).to eq(200)
        expect(parsed_body['id']).to eq(test_suite_id)
        expect(parsed_body).to include(*all_fields)
      end
    end

    context 'when the test_suite does not exist' do
      let(:test_suite_id) { SecureRandom.uuid }

      it 'renders a 404' do
        get router.path(:api_test_suite, id: test_suite_id)

        expect(last_response.status).to eq(404)
      end
    end
  end
end
