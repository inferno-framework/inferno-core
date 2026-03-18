require_relative '../../../lib/inferno/apps/cli/execute_script'

RSpec.describe Inferno::CLI::ExecuteScript do
  let(:suite_id) { 'demo' }
  let(:session_id) { 'test-session-id' }
  let(:run_id) { 'test-run-id' }
  let(:inferno_host) { 'https://inferno.example.com' }
  let(:create_url) { "#{inferno_host}/api/test_sessions" }
  let(:last_test_run_url) { "#{inferno_host}/api/test_sessions/#{session_id}/last_test_run" }
  let(:run_results_url) { "#{inferno_host}/api/test_runs/#{run_id}/results" }

  let(:base_options) do
    {
      inferno_base_url: inferno_host,
      compare_messages: false,
      compare_result_message: false,
      poll_interval: 0,
      default_poll_timeout: 5
    }
  end

  let(:session_response) do
    { 'id' => session_id, 'test_suite' => { 'test_groups' => [], 'tests' => [] } }
  end

  def build_instance(config, opts = base_options)
    allow(YAML).to receive(:safe_load_file).and_return(config)
    stub_request(:get, "#{inferno_host}/api/test_suites")
      .to_return(status: 200, body: [{ 'id' => suite_id, 'title' => suite_id }].to_json)
    stub_request(:post, create_url).to_return(status: 200, body: session_response.to_json)
    described_class.new('script.yaml', opts)
  end

  describe '#find_matching_step' do
    subject(:instance) { build_instance(config) }

    let(:steps) do
      [
        { 'status' => 'done', 'last_completed' => '', 'action' => 'END_SCRIPT' },
        { 'status' => 'waiting', 'last_completed' => 'test-1', 'action' => 'NOOP' },
        { 'status' => 'done', 'last_completed' => 'test-2', 'session' => 'session-b', 'command' => 'do_b' }
      ]
    end
    let(:config) { { 'sessions' => [{ 'suite' => suite_id }], 'steps' => steps } }

    it 'matches by status and last_completed' do
      result = instance.send(:find_matching_step, 'done', '', 'primary')
      expect(result['action']).to eq('END_SCRIPT')
    end

    it 'returns nil when no step matches the status' do
      expect(instance.send(:find_matching_step, 'running', '', 'primary')).to be_nil
    end

    it 'returns nil when last_completed does not match' do
      expect(instance.send(:find_matching_step, 'done', 'other-test', 'primary')).to be_nil
    end

    it 'matches a step with a session filter when the session key matches' do
      result = instance.send(:find_matching_step, 'done', 'test-2', 'session-b')
      expect(result['command']).to eq('do_b')
    end

    it 'does not match a session-filtered step when the session key differs' do
      expect(instance.send(:find_matching_step, 'done', 'test-2', 'session-a')).to be_nil
    end

    it 'matches a step with no session filter for any session key' do
      result = instance.send(:find_matching_step, 'waiting', 'test-1', 'any-session')
      expect(result['action']).to eq('NOOP')
    end
  end

  describe '#apply_templates' do
    subject(:instance) { build_instance(config) }

    let(:config) { { 'sessions' => [{ 'suite' => suite_id, 'name' => 'primary' }], 'steps' => [] } }

    let(:session_key) { 'primary' }
    let(:status) { {} }

    it 'substitutes {inferno_base_url}' do
      result = instance.send(:apply_templates, 'connect to {inferno_base_url}/auth', status, session_key)
      expect(result).to eq("connect to #{inferno_host}/auth")
    end

    it 'substitutes {session_id} with the current session id' do
      result = instance.send(:apply_templates, 'session={session_id}', status, session_key)
      expect(result).to eq("session=#{session_id}")
    end

    it 'leaves strings without tokens unchanged' do
      result = instance.send(:apply_templates, 'no tokens here', status, session_key)
      expect(result).to eq('no tokens here')
    end

    it 'substitutes {result_message} when present in status' do
      status_with_msg = { 'wait_result_message' => 'Please authorize' }
      result = instance.send(:apply_templates, 'msg={result_message}', status_with_msg, session_key)
      expect(result).to eq('msg=Please authorize')
    end

    it 'exits 3 when {result_message} is used but no wait_result_message is present' do
      expect do
        expect { instance.send(:apply_templates, '{result_message}', {}, session_key) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
    end

    it 'substitutes {NAME.session_id} with the named session id' do
      result = instance.send(:apply_templates, 'id={primary.session_id}', status, session_key)
      expect(result).to eq("id=#{session_id}")
    end

    it 'exits 3 when {NAME.session_id} refers to an unknown session' do
      expect do
        expect { instance.send(:apply_templates, '{unknown.session_id}', status, session_key) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
    end

    it 'substitutes {wait_outputs.KEY} from the current session status' do
      status_with_outputs = { 'wait_outputs' => [{ 'name' => 'redirect_url', 'value' => 'http://example.com' }] }
      result = instance.send(:apply_templates, 'url={wait_outputs.redirect_url}', status_with_outputs, session_key)
      expect(result).to eq('url=http://example.com')
    end

    it 'exits 3 when {wait_outputs.KEY} refers to an unknown output key' do
      status_with_outputs = { 'wait_outputs' => [] }
      expect do
        expect { instance.send(:apply_templates, '{wait_outputs.missing}', status_with_outputs, session_key) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
    end
  end

  describe '#compare_session' do
    subject(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    let(:expected_file) { '/tmp/expected_results.json' }
    let(:session) do
      Inferno::CLI::ExecuteScript::ScriptSession.new(
        key: 'primary',
        suite_id:,
        session_id:,
        expected_results_file: expected_file,
        short_id_map: {}
      )
    end
    let(:mock_compare) { instance_double(Inferno::CLI::Session::SessionCompare) }
    let(:mock_results) { instance_double(Inferno::CLI::Session::SessionResults) }

    before do
      allow(Inferno::CLI::Session::SessionCompare).to receive(:new).and_return(mock_compare)
      allow(Inferno::CLI::Session::SessionResults).to receive(:new).and_return(mock_results)
    end

    it 'returns true when expected_results_file is blank' do
      blank_session = Inferno::CLI::ExecuteScript::ScriptSession.new(
        key: 'primary', suite_id:, session_id:, expected_results_file: nil, short_id_map: {}
      )
      expect(instance.send(:compare_session, blank_session)).to be(true)
    end

    it 'returns true when the expected file exists and results match' do
      allow(File).to receive(:exist?).with(expected_file).and_return(true)
      allow(mock_compare).to receive(:results_match?).and_return(true)

      expect(instance.send(:compare_session, session)).to be(true)
    end

    it 'returns false and saves files when the expected file exists but results do not match' do
      allow(File).to receive(:exist?).with(expected_file).and_return(true)
      allow(mock_compare).to receive(:results_match?).and_return(false)
      allow(mock_compare).to receive(:save_actual_results_to_file)
      allow(mock_compare).to receive(:save_comparison_csv_to_file)

      expect(instance.send(:compare_session, session)).to be(false)
      expect(mock_compare).to have_received(:save_actual_results_to_file)
      expect(mock_compare).to have_received(:save_comparison_csv_to_file)
    end

    it 'returns false and writes actual results when the expected file does not exist' do
      allow(File).to receive(:exist?).with(expected_file).and_return(false)
      allow(mock_results).to receive(:results_for_session).with(session_id).and_return([{ 'result' => 'pass' }])
      allow(File).to receive(:write).with(expected_file, anything)

      expect(instance.send(:compare_session, session)).to be(false)
      expect(File).to have_received(:write).with(expected_file, anything)
    end
  end

  describe '#compare_options' do
    let(:base_config) { { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] } }

    it 'includes normalized_strings from the top-level YAML config (legacy fallback)' do
      config = base_config.merge('normalized_strings' => ['http://old.server.com', 'http://other.com'])
      instance = build_instance(config)
      session = instance.send(:sessions).first
      opts = instance.send(:compare_options, session)
      expect(opts[:normalized_strings]).to eq(['http://old.server.com', 'http://other.com'])
    end

    it 'returns an empty array for normalized_strings when not in YAML' do
      instance = build_instance(base_config)
      session = instance.send(:sessions).first
      opts = instance.send(:compare_options, session)
      expect(opts[:normalized_strings]).to eq([])
    end

    it 'reads normalized_strings from comparison_config' do
      config = base_config.merge('comparison_config' => { 'normalized_strings' => ['http://new.server.com'] })
      instance = build_instance(config)
      session = instance.send(:sessions).first
      opts = instance.send(:compare_options, session)
      expect(opts[:normalized_strings]).to eq(['http://new.server.com'])
    end

    it 'prefers comparison_config.normalized_strings over the top-level key' do
      config = base_config.merge(
        'normalized_strings' => ['http://old.server.com'],
        'comparison_config' => { 'normalized_strings' => ['http://new.server.com'] }
      )
      instance = build_instance(config)
      session = instance.send(:sessions).first
      opts = instance.send(:compare_options, session)
      expect(opts[:normalized_strings]).to eq(['http://new.server.com'])
    end

    it 'includes comparison_exclusions from comparison_config' do
      exclusions = [{ 'test_ids' => ['some-test'], 'reason' => 'known flaky' }]
      config = base_config.merge('comparison_config' => { 'comparison_exclusions' => exclusions })
      instance = build_instance(config)
      session = instance.send(:sessions).first
      opts = instance.send(:compare_options, session)
      expect(opts[:comparison_exclusions]).to eq(exclusions)
    end

    it 'returns an empty array for comparison_exclusions when not configured' do
      instance = build_instance(base_config)
      session = instance.send(:sessions).first
      opts = instance.send(:compare_options, session)
      expect(opts[:comparison_exclusions]).to eq([])
    end
  end

  describe 'orchestration' do
    let(:config) do
      {
        'sessions' => [{ 'suite' => suite_id }],
        'steps' => [{ 'status' => 'done', 'last_completed' => '', 'action' => 'END_SCRIPT' }]
      }
    end

    def stub_status_done
      stub_request(:get, last_test_run_url)
        .to_return(status: 200, body: { 'id' => run_id, 'status' => 'done' }.to_json)
      stub_request(:get, run_results_url)
        .to_return(status: 200, body: [].to_json)
    end

    it 'exits 0 when END_SCRIPT action is matched and comparison passes' do
      instance = build_instance(config)
      allow(instance).to receive(:results_match_expected?).and_return(true)
      stub_status_done

      expect { instance.run }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
    end

    it 'exits 3 when the status does not match any step' do
      instance = build_instance(config.merge('steps' => []))
      allow(instance).to receive(:results_match_expected?).and_return(true)
      stub_status_done

      expect { instance.run }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
    end

    it 'exits 3 when END_SCRIPT action is matched but comparison fails' do
      instance = build_instance(config)
      allow(instance).to receive(:results_match_expected?).and_return(false)
      stub_status_done

      expect { instance.run }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
    end

    it 'exits 3 on poll timeout' do
      instance = build_instance(config, base_options.merge(default_poll_timeout: -1))
      allow(instance).to receive(:results_match_expected?).and_return(true)
      stub_request(:get, last_test_run_url)
        .to_return(status: 200, body: { 'id' => run_id, 'status' => 'running' }.to_json)
      stub_request(:get, run_results_url)
        .to_return(status: 200, body: [].to_json)

      expect { instance.run }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
    end
  end

  describe '#handle_actionable_status' do
    subject(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    let(:session) { instance.send(:sessions).first }
    let(:timeout) { 5 }

    it 'sets failed and returns command nil on unmatched done status' do
      status = { 'status' => 'done' }
      result = instance.send(:handle_actionable_status, status, session, timeout)
      expect(result).to eq({ command: nil, timeout: timeout, next_poll_session: nil })
      expect(instance.execution_status.failed).to be true
    end

    it 'sets failed, cancels, and returns nil on unmatched waiting status' do
      status = { 'status' => 'waiting', 'last_test_executed' => 'some-test-id', 'id' => run_id }
      stub_request(:delete, "#{inferno_host}/api/test_runs/#{run_id}").to_return(status: 204)
      result = instance.send(:handle_actionable_status, status, session, timeout)
      expect(result).to be_nil
      expect(instance.execution_status.failed).to be true
      expect(a_request(:delete, "#{inferno_host}/api/test_runs/#{run_id}")).to have_been_made
    end
  end

  describe '#verify_step' do
    subject(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    let(:session) { instance.send(:sessions).first }
    let(:timeout) { 5 }
    let(:matched_step) { { command: 'some_command' } }

    it 'sets failed and returns command nil on loop detection for done status' do
      status = { 'status' => 'done' }
      instance.execution_status.last_step_signatures[session.key] = ['done', '']

      result = instance.send(:verify_step, matched_step, status, session, timeout)
      expect(result).to eq({ command: nil, timeout: timeout, next_poll_session: nil })
      expect(instance.execution_status.failed).to be true
    end

    it 'sets failed, cancels, and returns nil on loop detection for waiting status' do
      status = { 'status' => 'waiting', 'last_test_executed' => 'test-id', 'id' => run_id }
      instance.execution_status.last_step_signatures[session.key] = ['waiting', 'test-id']
      stub_request(:delete, "#{inferno_host}/api/test_runs/#{run_id}").to_return(status: 204)

      result = instance.send(:verify_step, matched_step, status, session, timeout)
      expect(result).to be_nil
      expect(instance.execution_status.failed).to be true
      expect(a_request(:delete, "#{inferno_host}/api/test_runs/#{run_id}")).to have_been_made
    end

    it 'does not set failed when a NOOP step repeats' do
      noop_step = { command: 'NOOP' }
      status = { 'status' => 'done' }
      instance.execution_status.last_step_signatures[session.key] = ['done', '']

      result = instance.send(:verify_step, noop_step, status, session, timeout)
      expect(result).to eq(noop_step)
      expect(instance.execution_status.failed).to be false
    end
  end
end
