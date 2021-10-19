require_relative '../../dev_suites/dev_smart/app_redirect_test'
require_relative '../request_helper'

RSpec.describe SMART::AppRedirectTest do
  include Rack::Test::Methods
  include RequestHelpers

  let(:test) { Inferno::Repositories::Tests.new.find('smart_app_redirect') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }
  let(:url) { 'http://example.com/fhir' }
  let(:inputs) do
    {
      client_id: 'CLIENT_ID',
      requested_scopes: 'REQUESTED_SCOPES',
      url: url,
      smart_authorization_url: 'http://example.com/auth'
    }
  end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  it 'waits and then passes when it receives a request with the correct state' do
    result = run(test, inputs)
    expect(result.result).to eq('wait')

    state = session_data_repo.load(test_session_id: test_session.id, name: 'state')
    get "/custom/smart/redirect?state=#{state}"

    result = results_repo.find(result.id)
    expect(result.result).to eq('pass')
  end

  it 'continues to wait when it receives a request with the incorrect state' do
    result = run(test, inputs)
    expect(result.result).to eq('wait')

    state = SecureRandom.uuid
    get "/custom/smart/redirect?state=#{state}"

    result = results_repo.find(result.id)
    expect(result.result).to eq('wait')
  end

  it 'fails if the authorization url is invalid' do
    result = run(test, smart_authorization_url: 'xyz')
    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/is not a valid URI/)
  end

  it "persists the incoming 'redirect' request" do
    run(test, inputs)
    state = session_data_repo.load(test_session_id: test_session.id, name: 'state')
    url = "/custom/smart/redirect?state=#{state}"
    get url

    request = requests_repo.find_named_request(test_session.id, 'redirect')
    expect(request.url).to end_with(url)
  end

  it "persists the 'state' output" do
    result = run(test, inputs)
    expect(result.result).to eq('wait')

    state = result.result_message.match(/with a state of `(.*)`/)[1]
    persisted_state = session_data_repo.load(test_session_id: test_session.id, name: 'state')

    expect(persisted_state).to eq(state)
  end
end
