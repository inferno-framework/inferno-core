require 'request_helper'

RSpec.describe Inferno::DSL::Runnable do
  include Rack::Test::Methods
  include RequestHelpers

  describe '.resume_test_route' do
    let(:test_suite) { Inferno::Repositories::TestSuites.new.find('demo') }
    let(:test_group) { Inferno::Repositories::TestGroups.new.find('demo-wait_group') }
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
end
