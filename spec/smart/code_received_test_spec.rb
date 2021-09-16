require_relative '../../dev_suites/dev_smart/code_received_test'
require_relative '../request_helper'

RSpec.describe SMART::CodeReceivedTest do
  include Rack::Test::Methods
  include RequestHelpers

  let(:test) { Inferno::Repositories::Tests.new.find('smart_code_received') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  def create_redirect_request(url)
    repo_create(
      :request,
      direction: 'incoming',
      name: 'redirect',
      url: url,
      test_session_id: test_session.id
    )
  end

  it 'passes if it receives a code with no error' do
    create_redirect_request('http://example.com/redirect?code=CODE')
    result = run(test, code: 'CODE')

    expect(result.result).to eq('pass')
  end

  it 'fails if it receives an error' do
    create_redirect_request('http://example.com/redirect?code=CODE&error=invalid_request')
    result = run(test, code: 'CODE')

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Error returned from authorization server/)
    expect(result.result_message).to include('invalid_request')
  end

  it 'includes the error description and uri in the failure message if present' do
    create_redirect_request(
      'http://example.com/redirect?code=CODE&error=invalid_request&error_description=DESCRIPTION&error_uri=URI'
    )
    result = run(test, code: 'CODE')

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Error returned from authorization server/)
    expect(result.result_message).to include('DESCRIPTION')
    expect(result.result_message).to include('URI')
  end
end
