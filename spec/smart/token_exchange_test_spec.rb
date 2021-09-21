require_relative '../../dev_suites/dev_smart/token_exchange_test'
require_relative '../request_helper'

RSpec.describe SMART::TokenExchangeTest do
  include Rack::Test::Methods
  include RequestHelpers

  let(:test) { Inferno::Repositories::Tests.new.find('smart_token_exchange') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }
  let(:url) { 'http://example.com/fhir' }
  let(:token_url) { 'http://example.com/token' }
  let(:public_inputs) do
    {
      code: 'CODE',
      smart_token_url: token_url,
      client_id: 'CLIENT_ID'
    }
  end
  let(:confidential_inputs) { public_inputs.merge(client_secret: 'CLIENT_SECRET') }

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

  context 'with a confidential client' do
    it 'passes if the token response has a 200 status' do
      create_redirect_request('http://example.com/redirect?code=CODE')
      stub_request(:post, token_url)
        .with(
          body:
            {
              grant_type: 'authorization_code',
              code: 'CODE',
              redirect_uri: 'http://localhost:4567/custom/smart/redirect'
            },
          headers: { 'Authorization' => "Basic #{Base64.strict_encode64('CLIENT_ID:CLIENT_SECRET')}" }
        )
        .to_return(status: 200)

      result = run(test, confidential_inputs)

      expect(result.result).to eq('pass')
    end
  end

  context 'with a public client' do
    it 'passes if the token response has a 200 status' do
      create_redirect_request('http://example.com/redirect?code=CODE')
      stub_request(:post, token_url)
        .with(
          body:
            {
              grant_type: 'authorization_code',
              code: 'CODE',
              client_id: 'CLIENT_ID',
              redirect_uri: described_class.config.options[:redirect_uri]
            }
        )
        .to_return(status: 200)

      result = run(test, public_inputs)

      expect(result.result).to eq('pass')
    end
  end

  it 'fails if a non-200 response is received' do
    create_redirect_request('http://example.com/redirect?code=CODE')
    stub_request(:post, token_url)
      .with(
        body:
          {
            grant_type: 'authorization_code',
            code: 'CODE',
            client_id: 'CLIENT_ID',
            redirect_uri: described_class.config.options[:redirect_uri]
          }
      )
      .to_return(status: 201)

    result = run(test, public_inputs)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Bad response status/)
  end

  it 'skips if the auth request had an error' do
    create_redirect_request('http://example.com/redirect?code=CODE&error=invalid_request')

    result = run(test, public_inputs)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('Error during authorization request')
  end
end
