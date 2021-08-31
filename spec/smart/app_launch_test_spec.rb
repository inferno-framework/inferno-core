require_relative '../../dev_suites/smart/app_launch_test'
require_relative '../request_helper'

RSpec.describe SMART::AppLaunchTest do
  include Rack::Test::Methods
  include RequestHelpers

  let(:test) { Inferno::Repositories::Tests.new.find('smart_app_launch') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }
  let(:url) { 'http://example.com/fhir' }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  it 'passes when a request is received with the provided url' do
    result = run(test, url: url)

    expect(result.result).to eq('wait')

    get "/custom/smart/launch?iss=#{url}"

    result = results_repo.find(result.id)

    expect(result.result).to eq('pass')
  end
end
