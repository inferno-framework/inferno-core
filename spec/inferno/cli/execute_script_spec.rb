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
    allow(File).to receive(:exist?).with('script.yaml').and_return(true)
    stub_request(:get, "#{inferno_host}/api/test_suites")
      .to_return(status: 200, body: [{ 'id' => suite_id, 'title' => suite_id }].to_json)
    stub_request(:post, create_url).to_return(status: 200, body: session_response.to_json)
    described_class.new('script.yaml', opts)
  end

  describe '#validate_yaml_file!' do
    it 'exits 1 with an error message when the file does not exist' do
      allow(File).to receive(:exist?).with('missing.yaml').and_return(false)
      expect do
        expect { described_class.new('missing.yaml', base_options) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
      end.to output(/File not found/).to_stdout
    end

    it 'exits 1 with an error message when the file does not have a yaml or yml extension' do
      allow(File).to receive(:exist?).with('script.txt').and_return(true)
      expect do
        expect { described_class.new('script.txt', base_options) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
      end.to output(/does not appear to be a YAML file/).to_stdout
    end

    it 'accepts a .yml extension' do
      allow(YAML).to receive(:safe_load_file).and_return({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] })
      allow(File).to receive(:exist?).with('script.yml').and_return(true)
      stub_request(:get, "#{inferno_host}/api/test_suites")
        .to_return(status: 200, body: [{ 'id' => suite_id, 'title' => suite_id }].to_json)
      stub_request(:post, create_url).to_return(status: 200, body: session_response.to_json)
      expect { described_class.new('script.yml', base_options) }.to_not raise_error
    end
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

  describe '#expand_file_input_path' do
    subject(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    it 'leaves non-@ values unchanged' do
      expect(instance.send(:expand_file_input_path, 'plain value')).to eq('plain value')
    end

    it 'leaves absolute @paths unchanged' do
      expect(instance.send(:expand_file_input_path, '@/absolute/path/file.json')).to eq('@/absolute/path/file.json')
    end

    it 'expands a relative @path to absolute using the yaml_file directory' do
      # build_instance passes 'script.yaml' as yaml_file; dirname is '.'
      expected = "@#{File.expand_path('data.json', '.')}"
      expect(instance.send(:expand_file_input_path, '@data.json')).to eq(expected)
    end

    it 'expands a relative @path with subdirectory components' do
      expected = "@#{File.expand_path('subdir/data.json', '.')}"
      expect(instance.send(:expand_file_input_path, '@subdir/data.json')).to eq(expected)
    end
  end

  describe '#apply_templates_to_start_run' do
    subject(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    let(:status) { {} }
    let(:session_key) { suite_id }

    it 'expands relative @paths in inputs to absolute paths after template substitution' do
      start_run = { 'runnable' => 'suite', 'inputs' => { 'coverage_json' => '@data.json' } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expected_path = "@#{File.expand_path('data.json', '.')}"
      expect(result['inputs']['coverage_json']).to eq(expected_path)
    end

    it 'leaves non-@ input values unchanged' do
      start_run = { 'runnable' => 'suite', 'inputs' => { 'url' => 'https://example.com' } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expect(result['inputs']['url']).to eq('https://example.com')
    end

    it 'does not apply template substitution to @path contents (file content is verbatim)' do
      # Template substitution runs on the raw YAML value before file expansion.
      # A plain string with a token is substituted; an @path is expanded but its
      # content (read at run time by start_run) is never touched by apply_templates.
      start_run = { 'runnable' => 'suite', 'inputs' => { 'url' => '{inferno_base_url}', 'data' => '@data.json' } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      # The plain token is substituted
      expect(result['inputs']['url']).to eq(inferno_host)
      # The @path is expanded but still an @path (file content not read here)
      expect(result['inputs']['data']).to start_with('@/')
    end

    it 'leaves absolute @paths unchanged' do
      start_run = { 'runnable' => 'suite', 'inputs' => { 'cert' => '@/etc/ssl/cert.pem' } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expect(result['inputs']['cert']).to eq('@/etc/ssl/cert.pem')
    end

    it 'JSON-serializes a Hash input value rather than using Ruby to_s format' do
      hash_value = { 'access_token' => 'TOKEN', 'auth_type' => 'public' }
      start_run = { 'runnable' => 'suite', 'inputs' => { 'auth_info' => hash_value } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expect(result['inputs']['auth_info']).to eq(hash_value.to_json)
      expect(result['inputs']['auth_info']).to_not include('=>')
    end

    it 'JSON-serializes an Array input value rather than using Ruby to_s format' do
      array_value = ['item1', 'item2']
      start_run = { 'runnable' => 'suite', 'inputs' => { 'list_input' => array_value } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expect(result['inputs']['list_input']).to eq(array_value.to_json)
    end
  end

  describe '#compare_session' do
    subject(:instance) do
      build_instance({
                       'sessions' => [{ 'suite' => suite_id }],
                       'steps' => [],
                       'comparison_config' => { 'expected_results_file' => expected_file }
                     })
    end

    let(:expected_file) { '/tmp/expected_results.json' }
    let(:mock_compare) { instance_double(Inferno::CLI::Session::SessionCompare) }
    let(:mock_results) { instance_double(Inferno::CLI::Session::SessionResults) }
    let(:session) do
      Inferno::CLI::ExecuteScript::ScriptSession.new(
        key: suite_id, suite_id:, session_id:, short_id_map: {}
      )
    end

    before do
      allow(Inferno::CLI::Session::SessionCompare).to receive(:new).and_return(mock_compare)
      allow(Inferno::CLI::Session::SessionResults).to receive(:new).and_return(mock_results)
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

    it 'returns an empty array for normalized_strings when not in YAML' do
      instance = build_instance(base_config)
      opts = instance.send(:compare_options, '/tmp/expected.json')
      expect(opts[:normalized_strings]).to eq([])
    end

    it 'reads normalized_strings from comparison_config' do
      config = base_config.merge('comparison_config' => { 'normalized_strings' => ['http://new.server.com'] })
      instance = build_instance(config)
      opts = instance.send(:compare_options, '/tmp/expected.json')
      expect(opts[:normalized_strings]).to eq(['http://new.server.com'])
    end

    it 'passes the expected_file through as expected_results_file' do
      instance = build_instance(base_config)
      opts = instance.send(:compare_options, '/tmp/my_expected.json')
      expect(opts[:expected_results_file]).to eq('/tmp/my_expected.json')
    end
  end

  describe '#resolve_expected_file_for_comparison' do
    let(:session_details_url) { "#{inferno_host}/api/test_sessions/#{session_id}" }

    let(:default_file) { '/tmp/default_expected.json' }
    let(:base_comparison_config) { { 'expected_results_file' => default_file } }

    it 'returns the default file when no alternate_expected_files are configured' do
      instance = build_instance({
                                  'sessions' => [{ 'suite' => suite_id }],
                                  'steps' => [],
                                  'comparison_config' => base_comparison_config
                                })
      session = Inferno::CLI::ExecuteScript::ScriptSession.new(
        key: suite_id, suite_id:, session_id:, short_id_map: {}
      )
      expect(instance.send(:resolve_expected_file_for_comparison, session)).to eq(default_file)
    end

    it 'returns the default file when no when conditions match' do
      config = {
        'sessions' => [{ 'suite' => suite_id }],
        'steps' => [],
        'comparison_config' => base_comparison_config.merge(
          'alternate_expected_files' => [
            { 'file' => 'alt_expected.json', 'when' => [{ 'field' => 'inputs.url', 'matches' => '^http://' }] }
          ]
        )
      }
      instance = build_instance(config)
      session = Inferno::CLI::ExecuteScript::ScriptSession.new(
        key: suite_id, suite_id:, session_id:, short_id_map: {}
      )
      stub_request(:get, session_details_url)
        .to_return(status: 200,
                   body: { 'test_suite' => {
                     'inputs' => [{ 'name' => 'url', 'value' => 'https://example.com' }]
                   } }.to_json)

      expect(instance.send(:resolve_expected_file_for_comparison, session)).to eq(default_file)
    end

    it 'returns the alternate file when all when conditions match' do
      config = {
        'sessions' => [{ 'suite' => suite_id }],
        'steps' => [],
        'comparison_config' => base_comparison_config.merge(
          'alternate_expected_files' => [
            { 'file' => 'alt_expected.json', 'when' => [{ 'field' => 'inputs.url', 'matches' => '^http://' }] }
          ]
        )
      }
      instance = build_instance(config)
      session = Inferno::CLI::ExecuteScript::ScriptSession.new(
        key: suite_id, suite_id:, session_id:, short_id_map: {}
      )
      stub_request(:get, session_details_url)
        .to_return(status: 200,
                   body: { 'test_suite' => {
                     'inputs' => [{ 'name' => 'url', 'value' => 'http://example.com' }]
                   } }.to_json)

      expect(instance.send(:resolve_expected_file_for_comparison, session)).to end_with('alt_expected.json')
    end

    it 'skips alternates with no when conditions' do
      config = {
        'sessions' => [{ 'suite' => suite_id }],
        'steps' => [],
        'comparison_config' => base_comparison_config.merge(
          'alternate_expected_files' => [{ 'file' => 'alt_expected.json' }]
        )
      }
      instance = build_instance(config)
      session = Inferno::CLI::ExecuteScript::ScriptSession.new(
        key: suite_id, suite_id:, session_id:, short_id_map: {}
      )
      stub_request(:get, session_details_url)
        .to_return(status: 200, body: {}.to_json)

      expect(instance.send(:resolve_expected_file_for_comparison, session)).to eq(default_file)
    end
  end

  describe '#session_detail_condition_matches?' do
    subject(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    it 'matches an input by name from test_suite.inputs' do
      details = { 'test_suite' => { 'inputs' => [{ 'name' => 'url', 'value' => 'http://example.com' }] } }
      cond = { 'field' => 'inputs.url', 'matches' => '^http://' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be true
    end

    it 'does not match when the input value does not satisfy the pattern' do
      details = { 'test_suite' => { 'inputs' => [{ 'name' => 'url', 'value' => 'https://example.com' }] } }
      cond = { 'field' => 'inputs.url', 'matches' => '^http://' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be false
    end

    it 'does not match when the named input is absent' do
      details = { 'test_suite' => { 'inputs' => [{ 'name' => 'other', 'value' => 'http://example.com' }] } }
      cond = { 'field' => 'inputs.url', 'matches' => '^http://' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be false
    end

    it 'matches configuration_messages when any message field matches the pattern' do
      details = {
        'test_suite' => {
          'configuration_messages' => [
            { 'type' => 'info', 'message' => 'Database connected successfully' },
            { 'type' => 'error', 'message' => 'Validator service unavailable' }
          ]
        }
      }
      cond = { 'field' => 'configuration_messages', 'matches' => 'unavailable' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be true
    end

    it 'does not match configuration_messages when no message field matches the pattern' do
      details = {
        'test_suite' => {
          'configuration_messages' => [
            { 'type' => 'info', 'message' => 'Database connected successfully' }
          ]
        }
      }
      cond = { 'field' => 'configuration_messages', 'matches' => 'unavailable' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be false
    end

    it 'does not match configuration_messages when the array is empty' do
      details = { 'test_suite' => { 'configuration_messages' => [] } }
      cond = { 'field' => 'configuration_messages', 'matches' => '.*' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be false
    end

    it 'matches using not_matches when no message matches the pattern' do
      details = { 'test_suite' => { 'configuration_messages' => [{ 'type' => 'info', 'message' => 'All good' }] } }
      cond = { 'field' => 'configuration_messages', 'not_matches' => 'unavailable' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be true
    end

    it 'does not match using not_matches when any message matches the pattern' do
      details = {
        'test_suite' => {
          'configuration_messages' => [{ 'type' => 'error', 'message' => 'Validator service unavailable' }]
        }
      }
      cond = { 'field' => 'configuration_messages', 'not_matches' => 'unavailable' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be false
    end

    it 'matches an input using not_matches when the value does not match the pattern' do
      details = { 'test_suite' => { 'inputs' => [{ 'name' => 'url', 'value' => 'https://example.com' }] } }
      cond = { 'field' => 'inputs.url', 'not_matches' => '^http://' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be true
    end

    it 'matches inferno_base_url against the configured base URL' do
      details = {}
      cond = { 'field' => 'inferno_base_url', 'matches' => 'inferno\.example\.com' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be true
    end

    it 'does not match inferno_base_url when the pattern does not match' do
      details = {}
      cond = { 'field' => 'inferno_base_url', 'matches' => 'other\.example\.com' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be false
    end

    it 'matches inferno_base_url using not_matches' do
      details = {}
      cond = { 'field' => 'inferno_base_url', 'not_matches' => 'other\.example\.com' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be true
    end

    it 'returns false for unsupported field names' do
      details = { 'test_suite_id' => 'my_suite' }
      cond = { 'field' => 'test_suite_id', 'matches' => 'my_' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be false
    end

    it 'returns false when field is missing from condition' do
      details = { 'test_suite' => { 'inputs' => [] } }
      cond = { 'matches' => 'my_' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be false
    end

    it 'returns false when both matches and not_matches are missing from condition' do
      details = { 'test_suite' => { 'inputs' => [] } }
      cond = { 'field' => 'inputs.url' }
      expect(instance.send(:session_detail_condition_matches?, cond, details)).to be false
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

  describe '#execute_command' do
    let(:config) { { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] } }
    let(:cmd) { 'bundle exec ruby my_script.rb' }

    context 'when --allow-commands is not set' do
      subject(:instance) { build_instance(config, base_options.merge(allow_commands: false)) }

      it 'returns false' do
        expect(instance.send(:execute_command, cmd)).to be false
      end
    end

    context 'when --allow-commands is set' do
      subject(:instance) { build_instance(config, base_options.merge(allow_commands: true)) }

      it 'returns true when the command succeeds' do
        expect(instance.send(:execute_command, 'true')).to be true
      end

      it 'returns false when the command fails' do
        expect(instance.send(:execute_command, 'false')).to be false
      end
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
