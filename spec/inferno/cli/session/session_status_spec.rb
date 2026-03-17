require_relative '../../../../lib/inferno/apps/cli/session/session_status'

RSpec.describe Inferno::CLI::Session::SessionStatus do
  let(:session_id) { 'test-session-id' }
  let(:run_id) { 'test-run-id' }
  let(:inferno_host) { 'https://inferno.healthit.gov/suites' }
  let(:options) { { inferno_base_url: inferno_host } }
  let(:last_test_run_url) { "#{inferno_host}/api/test_sessions/#{session_id}/last_test_run" }
  let(:run_results_url) { "#{inferno_host}/api/test_runs/#{run_id}/results" }

  def stub_last_test_run(body:, status: 200)
    stub_request(:get, last_test_run_url)
      .to_return(status: status, body: body)
  end

  def stub_run_results(body:, status: 200)
    stub_request(:get, run_results_url)
      .to_return(status: status, body: body)
  end

  describe '#run' do
    it 'outputs a default created status and exits 0 when no run has been started' do
      stub_last_test_run(body: '')

      expected_output = { test_session_id: session_id, status: 'created' }
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(expected_output)}\n").to_stdout
    end

    it 'outputs run data without last_test_executed and exits 0 when no test results exist' do
      run_data = { 'id' => run_id, 'status' => 'done' }
      stub_last_test_run(body: run_data.to_json)
      stub_run_results(body: [].to_json)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(run_data)}\n").to_stdout
    end

    it 'adds last_test_executed from the last result with a test_id and exits 0' do
      run_data = { 'id' => run_id, 'status' => 'done' }
      results = [
        { 'test_id' => 'test-first', 'result' => 'pass' },
        { 'test_id' => nil, 'result' => 'pass' },
        { 'test_id' => 'test-last', 'result' => 'fail' },
        { 'group_id' => 'group', 'result' => 'fail' }
      ]
      stub_last_test_run(body: run_data.to_json)
      stub_run_results(body: results.to_json)

      expected_output = run_data.merge('last_test_executed' => 'test-last')
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(expected_output)}\n").to_stdout
    end

    it 'adds wait_outputs and wait_result_message when the run is waiting and exits 0' do
      wait_outputs = [{ 'name' => 'redirect_url', 'value' => 'http://example.com/redirect' }]
      wait_message = 'Follow the redirect to authorize'
      run_data = { 'id' => run_id, 'status' => 'waiting' }
      results = [
        { 'test_id' => 'redirect_test', 'outputs' => wait_outputs, 'result_message' => wait_message }
      ]
      stub_last_test_run(body: run_data.to_json)
      stub_run_results(body: results.to_json)

      expected_output = run_data.merge(
        'last_test_executed' => 'redirect_test',
        'wait_outputs' => wait_outputs,
        'wait_result_message' => wait_message
      )
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(expected_output)}\n").to_stdout
    end

    it 'exits 3 and prints a not-found error when the session is not found' do
      stub_last_test_run(body: 'Not Found', status: 404)

      expected_error = { errors: "Session '#{session_id}' not found on Inferno host at '#{inferno_host}/'" }
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints a not-found error when the server returns a 404 with a non-JSON body' do
      stub_last_test_run(body: '<html><body>404 Not Found</body></html>', status: 404)

      expected_error = { errors: "Session '#{session_id}' not found on Inferno host at '#{inferno_host}/'" }
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints a connection error when Inferno is not reachable' do
      stub_request(:get, last_test_run_url)
        .to_raise(Faraday::ConnectionFailed.new('Connection refused'))

      expected_error = { errors: "Could not connect to Inferno at '#{inferno_host}/': Connection refused" }
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints the error body when the last_test_run request fails with a server error' do
      error_body = { errors: 'Internal server error' }
      stub_last_test_run(body: error_body.to_json, status: 500)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(error_body)}\n").to_stdout
    end

    it 'exits 3 and prints the error body when the run_results request fails with a server error' do
      run_data = { 'id' => run_id, 'status' => 'running' }
      error_body = { errors: 'Internal server error' }
      stub_last_test_run(body: run_data.to_json)
      stub_run_results(body: error_body.to_json, status: 500)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(error_body)}\n").to_stdout
    end
  end
end
