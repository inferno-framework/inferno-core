require_relative '../../../../lib/inferno/apps/cli/session/session_results'

RSpec.describe Inferno::CLI::Session::SessionResults do
  let(:session_id) { 'test-session-id' }
  let(:inferno_host) { 'https://inferno.healthit.gov/suites' }
  let(:results) do
    JSON.parse(File.read(File.join(__dir__, '..', '..', '..', 'fixtures', 'simple_session_results.json')))
  end
  let(:options) { { inferno_base_url: inferno_host } }
  let(:session_url) { "#{inferno_host}/api/test_sessions/#{session_id}" }
  let(:results_url) { "#{inferno_host}/api/test_sessions/#{session_id}/results" }

  def stub_session_exists
    stub_request(:get, session_url)
      .to_return(status: 200, body: {}.to_json)
  end

  describe '#run' do
    it 'outputs results as pretty-printed JSON and exits 0' do
      stub_session_exists
      results_request = stub_request(:get, results_url)
        .to_return(status: 200, body: results.to_json)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(results)}\n").to_stdout

      expect(results_request).to have_been_made.once
    end

    it 'exits 3 and prints a not-found error when the session is not found' do
      session_request = stub_request(:get, session_url)
        .to_return(status: 404, body: 'Not Found')

      expected_error = { errors: "Session '#{session_id}' not found on Inferno host at '#{inferno_host}/'" }
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

    it 'exits 3 and prints the error body when the results request fails' do
      stub_session_exists
      error_body = { errors: 'Internal server error' }
      stub_request(:get, results_url)
        .to_return(status: 500, body: error_body.to_json)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(error_body)}\n").to_stdout
    end
  end
end
