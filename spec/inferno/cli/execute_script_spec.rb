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

    it 'returns nil when expected_results_file is blank' do
      blank_session = Inferno::CLI::ExecuteScript::ScriptSession.new(
        key: 'primary', suite_id:, session_id:, expected_results_file: nil, short_id_map: {}
      )
      expect(instance.send(:compare_session, blank_session)).to be_nil
    end

    it 'returns 0 when the expected file exists and results match' do
      allow(File).to receive(:exist?).with(expected_file).and_return(true)
      allow(mock_compare).to receive(:results_match?).and_return(true)

      expect(instance.send(:compare_session, session)).to eq(0)
    end

    it 'returns 3 and saves files when the expected file exists but results do not match' do
      allow(File).to receive(:exist?).with(expected_file).and_return(true)
      allow(mock_compare).to receive(:results_match?).and_return(false)
      allow(mock_compare).to receive(:save_actual_results_to_file)
      allow(mock_compare).to receive(:save_comparison_csv_to_file)

      expect(instance.send(:compare_session, session)).to eq(3)
      expect(mock_compare).to have_received(:save_actual_results_to_file)
      expect(mock_compare).to have_received(:save_comparison_csv_to_file)
    end

    it 'returns 3 and writes actual results when the expected file does not exist' do
      allow(File).to receive(:exist?).with(expected_file).and_return(false)
      allow(mock_results).to receive(:results_for_session).with(session_id).and_return([{ 'result' => 'pass' }])
      allow(File).to receive(:write).with(expected_file, anything)

      expect(instance.send(:compare_session, session)).to eq(3)
      expect(File).to have_received(:write).with(expected_file, anything)
    end
  end

  describe '#compare_options' do
    let(:base_config) { { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] } }

    it 'includes normalized_strings from the YAML config' do
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
      allow(instance).to receive(:compare_or_save_results).and_return(0)
      stub_status_done

      expect { instance.run }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
    end

    it 'exits 1 when the status does not match any step' do
      instance = build_instance(config.merge('steps' => []))
      allow(instance).to receive(:compare_or_save_results).and_return(0)
      stub_status_done

      expect { instance.run }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end

    it 'exits 3 when END_SCRIPT action is matched but comparison fails' do
      instance = build_instance(config)
      allow(instance).to receive(:compare_or_save_results).and_return(3)
      stub_status_done

      expect { instance.run }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
    end
  end
end
