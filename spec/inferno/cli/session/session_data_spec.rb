require_relative '../../../../lib/inferno/apps/cli/session/session_data'

RSpec.describe Inferno::CLI::Session::SessionData do
  let(:session_id) { 'test-session-id' }
  let(:inferno_host) { 'https://inferno.healthit.gov/suites' }
  let(:session_data) do
    [
      { name: 'url', value: 'https://example.com/fhir', type: 'text' },
      { name: 'patient_id', value: '85', type: 'text' }
    ]
  end
  let(:options) { { inferno_base_url: inferno_host } }
  let(:session_url) { "#{inferno_host}/api/test_sessions/#{session_id}" }
  let(:data_url) { "#{inferno_host}/api/test_sessions/#{session_id}/session_data" }

  def stub_session_exists
    stub_request(:get, session_url)
      .to_return(status: 200, body: {}.to_json)
  end

  describe '#run' do
    it 'outputs session data as pretty-printed JSON and exits 0' do
      stub_session_exists
      data_request = stub_request(:get, data_url)
        .to_return(status: 200, body: session_data.to_json)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(session_data)}\n").to_stdout

      expect(data_request).to have_been_made.once
    end

    it 'exits 3 and prints a not-found error when the session is not found' do
      session_request = stub_request(:get, session_url)
        .to_return(status: 404, body: 'Not Found')

      expected_error = { errors: "Session '#{session_id}' not found on Inferno host at '#{inferno_host}'" }
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout

      expect(session_request).to have_been_made.once
    end

    it 'exits 3 and prints the error body when the session check fails with a server error' do
      error_body = { errors: 'Internal server error' }
      stub_request(:get, session_url)
        .to_return(status: 500, body: error_body.to_json)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(error_body)}\n").to_stdout
    end

    it 'exits 3 and prints a not-found error when the session data endpoint returns 404' do
      stub_session_exists
      stub_request(:get, data_url)
        .to_return(status: 404, body: 'Not Found')

      expected_error = { errors: "Session '#{session_id}' not found on Inferno host at '#{inferno_host}'" }
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints the error body when the session data request fails with a server error' do
      stub_session_exists
      error_body = { errors: 'Internal server error' }
      stub_request(:get, data_url)
        .to_return(status: 500, body: error_body.to_json)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(error_body)}\n").to_stdout
    end
  end
end
