require_relative '../../dev_suites/smart/launch_received_test'
require_relative '../request_helper'

RSpec.describe SMART::LaunchReceivedTest do
  include Rack::Test::Methods
  include RequestHelpers

  let(:test) { Inferno::Repositories::Tests.new.find('smart_launch_received') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
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

  it 'outputs the launch parameter' do
    repo_create(
      :request,
      name: 'launch',
      url: "http://example.com/?launch=#{url}",
      test_session_id: test_session.id
    )

    result = run(test)

    expect(result.result).to eq('pass')

    launch = session_data_repo.load(test_session_id: test_session.id, name: :launch)

    expect(launch).to eq(url)
  end
end
