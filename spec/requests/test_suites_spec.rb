require 'request_helper'

RSpec.describe '/test_suites' do
  let(:router) { Inferno::Web::Router }
  let(:repo) { Inferno::Repositories::TestSuites.new }
  let(:summary_fields) { ['id', 'title'] }
  let(:full_fields) { ['test_groups'] }
  let(:all_fields) { summary_fields.concat(full_fields) }

  describe 'index' do
    let(:index_path) { router.path(:api_test_suites_index) }

    it 'renders json of test_suite summaries' do
      get index_path

      expect(last_response.status).to eq(200)

      test_suites = parsed_body

      expect(test_suites.length).to eq(repo.all.length)
      expect(test_suites).to all(include(*summary_fields))
      expect(test_suites).to all(exclude(*full_fields))
      expect(test_suites).to all(have_key('links'))
      expect(test_suites.map { |ts| ts['links'] }).to all(be_an(Array))
    end
  end

  describe 'show' do
    context 'when the test_suite exists and has defined links' do
      let(:test_suite_id) { 'demo' }

      it 'renders the test_suite json' do
        get router.path(:api_test_suites_show, id: test_suite_id)
        expect(last_response.status).to eq(200)
        expect(parsed_body['id']).to eq(test_suite_id)
        expect(parsed_body).to include(*all_fields)
        expect(parsed_body['links']).to be_an(Array)
        parsed_body['links'].each do |link|
          expect(link).to be_a(Hash)
          expect(link).to include('type', 'label', 'url')
          expect(link['type']).to be_a(String)
          expect(link['label']).to be_a(String)
          expect(link['url']).to be_a(String)
        end
      end
    end

    context 'when the test_suite does not exist' do
      let(:test_suite_id) { SecureRandom.uuid }

      it 'renders a 404' do
        get router.path(:api_test_suites_show, id: test_suite_id)

        expect(last_response.status).to eq(404)
      end
    end

    context 'when the test_suite has requirement sets' do
      let(:test_suite_id) { 'ig_requirements' }

      it 'includes the requirement sets' do
        get router.path(:api_test_suites_show, id: test_suite_id)
        expect(last_response.status).to eq(200)

        received_sets = parsed_body['requirement_sets']

        expect(received_sets).to be_present
        expect(received_sets.length).to eq(2)
        expect(received_sets.first['identifier']).to be_present
        expect(received_sets.first['title']).to be_present
      end
    end
  end

  describe 'check_configuration' do
    context 'when the test_suite exists' do
      let(:test_suite_id) { 'demo' }

      it 'renders the test_suite json' do
        put router.path(:api_test_suites_check_configuration, id: test_suite_id)

        expect(last_response.status).to eq(200)

        message_keys = ['type', 'message']

        expect(parsed_body).to be_an(Array)
        parsed_body.each do |message_hash|
          expect(message_hash.keys).to match_array(message_keys)
        end
      end
    end

    context 'when the test_suite does not exist' do
      let(:test_suite_id) { SecureRandom.uuid }

      it 'renders a 404' do
        put router.path(:api_test_suites_check_configuration, id: test_suite_id)

        expect(last_response.status).to eq(404)
      end
    end
  end

  describe 'requirements' do
    let(:test_session) { repo_create(:test_session, test_suite_id:) }
    let(:test_suite_id) { 'ig_requirements' }

    context 'when optional session id provided' do
      it 'renders json of requirements detail for the suite when suite and session exist' do
        get "#{router.path(:api_test_suites_requirements, id: test_suite_id)}?session_id=#{test_session.id}"

        expect(last_response.status).to eq(200)

        requirements = parsed_body
        test_suite = repo.find(test_suite_id)
        expected_requirements =
          Inferno::Repositories::Requirements.new.requirements_for_suite(test_suite.id, test_session.id)
        expect(requirements.length).to eq(expected_requirements.length)
        expect(requirements.map { |req| req['id'] }).to include(*expected_requirements.map(&:id))
      end

      it 'renders a 404 when test suite does not exist' do
        get "#{router.path(:api_test_suites_requirements, id: 'test_suite_id')}?session_id=#{test_session.id}"

        expect(last_response.status).to eq(404)
        expect(last_response.body).to include('Test Suite `test_suite_id` not found')
      end

      it 'renders a 404 when test session does not exist' do
        get "#{router.path(:api_test_suites_requirements, id: test_suite_id)}?session_id=random"

        expect(last_response.status).to eq(404)
        expect(last_response.body).to include('Test session `random` not found')
      end
    end

    context 'when optional session id not provided' do
      it 'renders json of requirements detail for the suite when suite exists' do
        get router.path(:api_test_suites_requirements, id: test_suite_id)

        expect(last_response.status).to eq(200)

        requirements = parsed_body
        test_suite = repo.find(test_suite_id)
        expected_requirements = Inferno::Repositories::Requirements.new.requirements_for_suite(test_suite.id)
        expect(requirements.length).to eq(expected_requirements.length)
        expect(requirements.map { |req| req['id'] }).to include(*expected_requirements.map(&:id))
      end

      it 'renders a 404 when test suite does not exist' do
        get router.path(:api_test_suites_requirements, id: 'test_suite_id')

        expect(last_response.status).to eq(404)
        expect(last_response.body).to include('Test Suite `test_suite_id` not found')
      end
    end
  end
end
