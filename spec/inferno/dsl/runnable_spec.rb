require 'request_helper'

RSpec.describe Inferno::DSL::Runnable do
  include Rack::Test::Methods
  include RequestHelpers
  let(:test_suites_repo) { Inferno::Repositories::TestSuites.new }
  let(:test_groups_repo) { Inferno::Repositories::TestGroups.new }

  describe '.resume_test_route' do
    let(:test_suite) { test_suites_repo.find('demo') }
    let(:test_group) { test_groups_repo.find('demo-wait_group') }
    let(:wait_test) { test_group.tests[1] }
    let(:test_session) { repo_create(:test_session, test_suite_id: test_suite.id) }
    let!(:test_run) do
      repo_create(
        :test_run,
        test_session_id: test_session.id,
        runnable: { test_group_id: test_group.id },
        identifier: 'IDENTIFIER',
        status: 'waiting',
        wait_timeout: Time.now + 300.seconds
      )
    end

    let!(:result) do
      repo_create(
        :result,
        test_run_id: test_run.id,
        runnable: wait_test.reference_hash,
        result_message: 'waiting for incoming request',
        result: 'wait'
      )
    end

    context 'when the identifier does not match a test run' do
      it 'renders a 500 error' do
        get '/custom/demo/resume?xyz=BAD_IDENTIFIER'
        expect(last_response.status).to eq(500)
      end
    end

    context 'when the wait timeout has been passed' do
      it 'renders a 500 error' do
        Inferno::Repositories::TestRuns.new.update(test_run.id, wait_timeout: Time.now - 5.seconds)
        get '/custom/demo/resume?xyz=IDENTIFIER'
        expect(last_response.status).to eq(500)
      end
    end

    context 'when a matching test run is found' do
      it 'redirects the user to the waiting group' do
        get '/custom/demo/resume?xyz=IDENTIFIER'

        expect(last_response.status).to eq(302)

        location_header = last_response.get_header('location')

        expect(location_header).to eq("/test_sessions/#{test_session.id}##{test_group.id}")
      end

      it 'updates the waiting test result' do
        get '/custom/demo/resume?xyz=IDENTIFIER'

        updated_result = Inferno::Repositories::Results.new.find(result.id)

        expect(updated_result.result).to eq('pass')
        expect(updated_result.result_message).to be_nil
      end

      it 'updates the waiting test run' do
        get '/custom/demo/resume?xyz=IDENTIFIER'

        updated_run = Inferno::Repositories::TestRuns.new.find(test_run.id)

        expect(updated_run.identifier).to be_nil
      end
    end
  end

  describe '.test_count' do
    it 'returns 1 for a test' do
      klass = Class.new(Inferno::Entities::Test)

      expect(klass.test_count).to eq(1)
    end

    it 'returns the number of tests in a non-nested group' do
      group = test_groups_repo.find('DemoIG_STU1::DemoGroup')

      expect(group.test_count).to eq(group.children.length)
    end

    it 'returns the total number of tests in a nested group' do
      base_group = test_groups_repo.find('DemoIG_STU1::DemoGroup')
      parent_group = test_suites_repo.find('demo').children[1]

      expect(parent_group.test_count).to eq(base_group.test_count * 2)
    end

    it 'returns the total number of tests in a suite' do
      demo_group = test_groups_repo.find('DemoIG_STU1::DemoGroup')
      wait_group = test_groups_repo.find('demo-wait_group')
      suite = test_suites_repo.find('demo')

      expect(suite.test_count).to eq(demo_group.test_count * 3 + wait_group.test_count)
    end
  end
end
