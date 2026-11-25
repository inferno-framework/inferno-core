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
      compare_requests: true,
      compare_io: true,
      poll_interval: 0,
      default_poll_timeout: 5
    }
  end

  let(:session_response) do
    { 'id' => session_id, 'test_suite' => { 'test_groups' => [], 'tests' => [] } }
  end

  before { allow(File).to receive(:exist?).and_call_original }

  def build_instance(config, opts = base_options, session_ids: [session_id])
    allow(YAML).to receive(:safe_load_file).and_return(config)
    allow(File).to receive(:exist?).with('script.yaml').and_return(true)
    stub_request(:get, "#{inferno_host}/api/test_suites")
      .to_return(status: 200, body: [{ 'id' => suite_id, 'title' => suite_id }].to_json)
    stub_request(:post, create_url)
      .to_return(*session_ids.map { |id| { status: 200, body: session_response.merge('id' => id).to_json } })
    described_class.new('script.yaml', opts)
  end

  def expect_exit_with_error(config, message)
    expect do
      expect { build_instance(config) }
        .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end.to output(message).to_stdout
  end

  def single_session_config(comparison_config)
    { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [], 'comparison_config' => comparison_config }
  end

  def multi_session_config(comparison_config)
    {
      'sessions' => [{ 'suite' => suite_id, 'name' => 'receiver' }, { 'suite' => suite_id, 'name' => 'sender' }],
      'steps' => [],
      'comparison_config' => comparison_config
    }
  end

  describe 'session creation logging' do
    # warn is silent when $VERBOSE is nil
    around do |example|
      verbose = $VERBOSE
      $VERBOSE = false
      example.run
    ensure
      $VERBOSE = verbose
    end

    it 'includes the session name after the suite when a name is given' do
      config = { 'sessions' => [{ 'suite' => suite_id, 'name' => 'consumer' }], 'steps' => [] }
      expect { build_instance(config) }
        .to output(/Creating session for suite '#{suite_id}' with name 'consumer'\.\.\./)
        .to_stderr
    end

    it 'only includes the suite when no name is given' do
      config = { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }
      expect { build_instance(config) }
        .to output(/Creating session for suite '#{suite_id}'\.\.\./)
        .to_stderr
    end
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
    subject(:instance) { build_instance(config, base_options.merge(allow_commands: true)) }

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

  describe '#resolve_short_id' do
    # resolve_short_id is called lazily via scripted_steps when `steps` is first accessed.

    it 'exits 3 when last_completed is a short ID referencing a session name that does not exist' do
      step = { 'status' => 'done', 'last_completed' => '1.01', 'session' => 'nonexistent', 'action' => 'END_SCRIPT' }
      config = { 'sessions' => [{ 'suite' => suite_id, 'name' => 'primary' }], 'steps' => [step] }
      instance = build_instance(config)
      expected_error = { errors: "Session 'nonexistent' not found in script sessions" }

      expect do
        expect { instance.send(:steps) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 when last_completed is a short ID referencing an unknown session name in a multi-session script' do
      step = { 'status' => 'done', 'last_completed' => '1.01', 'session' => 'wrong', 'action' => 'END_SCRIPT' }
      config = {
        'sessions' => [{ 'suite' => suite_id, 'name' => 'primary' }, { 'suite' => suite_id, 'name' => 'secondary' }],
        'steps' => [step]
      }
      stub_request(:post, create_url).to_return(status: 200, body: session_response.to_json)
      instance = build_instance(config)
      expected_error = { errors: "Session 'wrong' not found in script sessions" }

      expect do
        expect { instance.send(:steps) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
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

    it 'substitutes {inferno_base_url} with the configured base_url when no option is given' do
      instance.send(:options=, base_options.except(:inferno_base_url))
      result = instance.send(:apply_templates, 'connect to {inferno_base_url}/auth', status, session_key)
      expect(result).to eq("connect to #{Inferno::Application['base_url']}/auth")
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

    it 'substitutes {NAME.session_id} inside a multi-line JSON object' do
      result = instance.send(:apply_templates, %({\n  "id": "{primary.session_id}"\n}), status, session_key)
      expect(result).to eq(%({\n  "id": "#{session_id}"\n}))
    end

    it 'substitutes {NAME.wait_outputs.KEY} inside a multi-line JSON object' do
      instance.execution_status.cross_session_status['primary'] =
        { 'wait_outputs' => [{ 'name' => 'note', 'value' => 'a "quoted" value' }] }
      result = instance.send(:apply_templates, %({\n  "note": "{primary.wait_outputs.note}"\n}), status, session_key,
                             json_string: true)
      expect(JSON.parse(result)).to eq({ 'note' => 'a "quoted" value' })
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

    it 'leaves absolute @paths unchanged when the file exists' do
      allow(File).to receive(:exist?).with('/absolute/path/file.json').and_return(true)
      expect(instance.send(:expand_file_input_path, '@/absolute/path/file.json')).to eq('@/absolute/path/file.json')
    end

    it 'expands a relative @path to absolute using the yaml_file directory' do
      # build_instance passes 'script.yaml' as yaml_file; dirname is '.'
      expected_path = File.expand_path('data.json', '.')
      allow(File).to receive(:exist?).with(expected_path).and_return(true)
      expect(instance.send(:expand_file_input_path, '@data.json')).to eq("@#{expected_path}")
    end

    it 'expands a relative @path with subdirectory components' do
      expected_path = File.expand_path('subdir/data.json', '.')
      allow(File).to receive(:exist?).with(expected_path).and_return(true)
      expect(instance.send(:expand_file_input_path, '@subdir/data.json')).to eq("@#{expected_path}")
    end

    it 'exits 3 and prints an error when an absolute @path file does not exist' do
      path = '/nonexistent/path/file.json'
      allow(File).to receive(:exist?).with(path).and_return(false)
      expected_error = { errors: "File input not found: #{path}" }
      expect do
        expect { instance.send(:expand_file_input_path, "@#{path}") }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints an error when a relative @path file does not exist' do
      expanded_path = File.expand_path('missing.json', '.')
      allow(File).to receive(:exist?).with(expanded_path).and_return(false)
      expected_error = { errors: "File input not found: #{expanded_path}" }
      expect do
        expect { instance.send(:expand_file_input_path, '@missing.json') }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end
  end

  describe '#resolve_command' do
    subject(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    let(:path) { File.expand_path('data.json', '.') }
    let(:step) do
      {
        'status' => 'waiting',
        'last_completed' => 'wait-test',
        'start_run' => {
          'runnable' => 'suite',
          'inputs' => { 'url' => '{wait_outputs.url}', 'data' => '@data.json' }
        }
      }
    end

    def waiting_status(url)
      { 'status' => 'waiting', 'wait_outputs' => [{ 'name' => 'url', 'value' => url }] }
    end

    before do
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path, encoding: 'UTF-8').and_return('{"url": "{wait_outputs.url}"}')
    end

    it 'does not modify the step when substituting template tokens in start_run inputs' do
      original_step = step.deep_dup
      instance.send(:resolve_command, step, waiting_status('http://first.example.com'), suite_id)
      expect(step).to eq(original_step)
    end

    it 'substitutes values from the current status each time the step is resolved' do
      first = instance.send(:resolve_command, step, waiting_status('http://first.example.com'), suite_id)
      second = instance.send(:resolve_command, step, waiting_status('http://second.example.com'), suite_id)

      expect(first[:start_run]['inputs']).to eq(
        'url' => 'http://first.example.com', 'data' => '{"url": "http://first.example.com"}'
      )
      expect(second[:start_run]['inputs']).to eq(
        'url' => 'http://second.example.com', 'data' => '{"url": "http://second.example.com"}'
      )
    end
  end

  describe '#apply_templates_to_start_run' do
    subject(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    let(:status) { {} }
    let(:session_key) { suite_id }

    it 'expands relative @paths in inputs to absolute paths after template substitution' do
      expected_path = File.expand_path('data.json', '.')
      allow(File).to receive(:exist?).with(expected_path).and_return(true)
      allow(File).to receive(:read).with(expected_path, encoding: 'UTF-8').and_return('{"no": "tokens"}')
      start_run = { 'runnable' => 'suite', 'inputs' => { 'coverage_json' => '@data.json' } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expect(result['inputs']['coverage_json']).to eq("@#{expected_path}")
    end

    it 'leaves non-@ input values unchanged' do
      start_run = { 'runnable' => 'suite', 'inputs' => { 'url' => 'https://example.com' } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expect(result['inputs']['url']).to eq('https://example.com')
    end

    it 'replaces an @path input with its content when the file contains template tokens' do
      path = File.expand_path('data.json', '.')
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path, encoding: 'UTF-8').and_return('{"url": "{inferno_base_url}/fhir"}')
      start_run = { 'runnable' => 'suite', 'inputs' => { 'url' => '{inferno_base_url}', 'data' => '@data.json' } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expect(result['inputs']['url']).to eq(inferno_host)
      expect(result['inputs']['data']).to eq(%({"url": "#{inferno_host}/fhir"}))
    end

    it 'leaves an @path input unchanged when the file contains no template tokens' do
      path = File.expand_path('data.json', '.')
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path, encoding: 'UTF-8').and_return('{"url": "https://example.com"}')
      start_run = { 'runnable' => 'suite', 'inputs' => { 'data' => '@data.json' } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expect(result['inputs']['data']).to eq("@#{path}")
    end

    it 'leaves an @path input unchanged when the file is not valid text' do
      path = File.expand_path('data.bin', '.')
      allow(File).to receive(:exist?).with(path).and_return(true)
      allow(File).to receive(:read).with(path, encoding: 'UTF-8')
        .and_return("\xFF{session_id}".dup.force_encoding('UTF-8'))
      start_run = { 'runnable' => 'suite', 'inputs' => { 'data' => '@data.bin' } }
      result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
      expect(result['inputs']['data']).to eq("@#{path}")
    end

    it 'substitutes tokens in a UTF-8 file with non-ASCII content regardless of the default encoding' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'data.json')
        File.write(path, '{"name": "José", "url": "{inferno_base_url}"}', encoding: 'UTF-8')
        allow(File).to receive(:exist?).and_call_original
        original_external = Encoding.default_external
        begin
          silence_warnings { Encoding.default_external = Encoding::US_ASCII }
          start_run = { 'runnable' => 'suite', 'inputs' => { 'data' => "@#{path}" } }
          result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
          expect(result['inputs']['data']).to eq(%({"name": "José", "url": "#{inferno_host}"}))
        ensure
          silence_warnings { Encoding.default_external = original_external }
        end
      end
    end

    it 'leaves absolute @paths unchanged when the file exists' do
      allow(File).to receive(:exist?).with('/etc/ssl/cert.pem').and_return(true)
      allow(File).to receive(:read).with('/etc/ssl/cert.pem', encoding: 'UTF-8').and_return('CERT')
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

    context 'when a substituted value contains characters that must be escaped in JSON' do
      let(:status) { { 'wait_result_message' => %(Say "hi"\\\nthere) } }

      it 'JSON-escapes values substituted into a Hash input' do
        start_run = { 'runnable' => 'suite', 'inputs' => { 'auth_info' => { 'note' => '{result_message}' } } }
        result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
        expect(JSON.parse(result['inputs']['auth_info'])).to eq({ 'note' => status['wait_result_message'] })
      end

      it 'JSON-escapes values substituted into a .json file input' do
        path = File.expand_path('data.json', '.')
        allow(File).to receive(:exist?).with(path).and_return(true)
        allow(File).to receive(:read).with(path, encoding: 'UTF-8').and_return('{"note": "{result_message}"}')
        start_run = { 'runnable' => 'suite', 'inputs' => { 'data' => '@data.json' } }
        result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
        expect(JSON.parse(result['inputs']['data'])).to eq({ 'note' => status['wait_result_message'] })
      end

      it 'does not escape values substituted into a non-JSON file input' do
        path = File.expand_path('note.txt', '.')
        allow(File).to receive(:exist?).with(path).and_return(true)
        allow(File).to receive(:read).with(path, encoding: 'UTF-8').and_return('note: {result_message}')
        start_run = { 'runnable' => 'suite', 'inputs' => { 'data' => '@note.txt' } }
        result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
        expect(result['inputs']['data']).to eq("note: #{status['wait_result_message']}")
      end

      it 'does not escape values substituted into a plain string input' do
        start_run = { 'runnable' => 'suite', 'inputs' => { 'note' => 'note: {result_message}' } }
        result = instance.send(:apply_templates_to_start_run, start_run, status, session_key)
        expect(result['inputs']['note']).to eq("note: #{status['wait_result_message']}")
      end
    end
  end

  describe '#session_id_normalized_strings' do
    let(:config) do
      {
        'sessions' => [{ 'suite' => suite_id, 'name' => 'receiver' }, { 'suite' => suite_id, 'name' => 'sender' }],
        'steps' => []
      }
    end

    it 'maps the id of every session to a per-session placeholder' do
      instance = build_instance(config, session_ids: ['new-receiver', 'new-sender'])

      expect(instance.send(:session_id_normalized_strings)).to eq(
        [
          { 'pattern' => 'new-receiver', 'replacement' => '<receiver.session_id>' },
          { 'pattern' => 'new-sender', 'replacement' => '<sender.session_id>' }
        ]
      )
    end

    it 'makes actual results match expected results stored with session id placeholders' do
      expected = { 'test_id' => 'test-1', 'result' => 'pass',
                   'requests' => [{ 'direction' => 'outgoing', 'verb' => 'get', 'status' => 200,
                                    'url' => 'http://host/inferno/demo/<receiver.session_id>' }] }
      actual = expected.merge('requests' => [expected['requests'].first.merge(
        'url' => 'http://host/inferno/demo/new-receiver'
      )])
      instance = build_instance(config, session_ids: ['new-receiver', 'new-sender'])

      compared = Inferno::CLI::Session::SessionCompare::ComparedTestResult.new(
        'test-1', expected, actual,
        { compare_requests: true, normalized_strings: instance.send(:session_id_normalized_strings) }
      )
      expect(compared.same_result?).to be(true)
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
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(expected_file).and_return('[]')
    end

    it 'returns true when the expected file exists and results match' do
      allow(File).to receive(:exist?).with(expected_file).and_return(true)
      allow(mock_compare).to receive(:results_match?).and_return(true)

      expect(instance.send(:compare_session, session)).to be(true)
    end

    it 'returns false and saves files when the expected file exists but results do not match' do
      allow(File).to receive(:exist?).with(expected_file).and_return(true)
      allow(mock_compare).to receive_messages(results_match?: false, expected_results: [])
      allow(mock_compare).to receive(:save_actual_results_to_file)
      allow(mock_compare).to receive(:save_comparison_csv_to_file)

      expect(instance.send(:compare_session, session)).to be(false)
      expect(mock_compare).to have_received(:save_actual_results_to_file)
      expect(mock_compare).to have_received(:save_comparison_csv_to_file)
    end

    context 'when results do not match' do
      around do |example|
        verbose = $VERBOSE
        $VERBOSE = false
        example.run
      ensure
        $VERBOSE = verbose
      end

      before do
        allow(File).to receive(:exist?).with(expected_file).and_return(true)
        allow(mock_compare).to receive(:results_match?).and_return(false)
        allow(mock_compare).to receive(:save_actual_results_to_file)
        allow(mock_compare).to receive(:save_comparison_csv_to_file)
      end

      it 'suggests regenerating expected results that are in the older format' do
        allow(mock_compare).to receive(:expected_results)
          .and_return([{ 'test_id' => 'test-1', 'result' => 'pass', 'test_session_id' => 'old-id' }])

        expect { instance.send(:compare_session, session) }
          .to output(/older format.*regenerate them with -u/).to_stderr
      end

      it 'does not suggest regenerating expected results in the stored format' do
        allow(mock_compare).to receive(:expected_results).and_return([{ 'test_id' => 'test-1', 'result' => 'pass' }])

        expect { instance.send(:compare_session, session) }.to_not output(/older format/).to_stderr
      end
    end

    it 'returns false and writes pretty-printed actual results when the expected file does not exist' do
      results = [{ 'result' => 'pass' }]
      allow(File).to receive(:exist?).with(expected_file).and_return(false)
      allow(mock_results).to receive(:results_for_session).with(session_id).and_return(results)
      allow(File).to receive(:write).with(expected_file, anything)

      expect(instance.send(:compare_session, session)).to be(false)
      expect(File).to have_received(:write).with(expected_file, "#{JSON.pretty_generate(results)}\n")
    end

    it 'writes expected results in normalized form, with session ids replaced and test_session_id dropped' do
      results = [{ 'test_id' => 'test-1', 'result' => 'pass', 'test_session_id' => session_id,
                   'requests' => [{ 'direction' => 'outgoing', 'verb' => 'get', 'status' => 200,
                                    'url' => "#{inferno_host}/custom/#{session_id}/resume" }] }]
      allow(File).to receive(:exist?).with(expected_file).and_return(false)
      allow(mock_results).to receive(:results_for_session).with(session_id).and_return(results)
      allow(File).to receive(:write).with(expected_file, anything)

      instance.send(:compare_session, session)

      expected = [{ 'test_id' => 'test-1', 'result' => 'pass',
                    'requests' => [{ 'direction' => 'outgoing', 'verb' => 'get', 'status' => 200,
                                     'url' => "<inferno_base_url>/custom/<#{suite_id}.session_id>/resume" }] }]
      expect(File).to have_received(:write).with(expected_file, satisfy { |json| JSON.parse(json) == expected })
    end

    it 'keeps the fields of comparisons turned off on the command line in the written expected results' do
      instance = build_instance({
                                  'sessions' => [{ 'suite' => suite_id }],
                                  'steps' => [],
                                  'comparison_config' => { 'expected_results_file' => expected_file }
                                }, base_options.merge(compare_io: false))
      results = [{ 'test_id' => 'test-1', 'result' => 'pass',
                   'outputs' => [{ 'name' => 'token', 'value' => 'abc' }] }]
      allow(File).to receive(:exist?).with(expected_file).and_return(false)
      allow(mock_results).to receive(:results_for_session).with(session_id).and_return(results)
      allow(File).to receive(:write).with(expected_file, anything)

      instance.send(:compare_session, session)

      expect(File).to have_received(:write).with(expected_file, satisfy { |json| JSON.parse(json) == results })
    end

    it 'leaves the fields of comparisons turned off in comparison_config out of the written expected results' do
      instance = build_instance({
                                  'sessions' => [{ 'suite' => suite_id }],
                                  'steps' => [],
                                  'comparison_config' => { 'expected_results_file' => expected_file,
                                                           'compare_requests' => false }
                                })
      results = [{ 'test_id' => 'test-1', 'result' => 'pass',
                   'outputs' => [{ 'name' => 'token', 'value' => 'abc' }],
                   'requests' => [{ 'direction' => 'outgoing', 'verb' => 'get', 'status' => 200,
                                    'url' => 'http://example.com/varies' }] }]
      allow(File).to receive(:exist?).with(expected_file).and_return(false)
      allow(mock_results).to receive(:results_for_session).with(session_id).and_return(results)
      allow(File).to receive(:write).with(expected_file, anything)

      instance.send(:compare_session, session)

      expected = [{ 'test_id' => 'test-1', 'result' => 'pass', 'outputs' => [{ 'name' => 'token', 'value' => 'abc' }] }]
      expect(File).to have_received(:write).with(expected_file, satisfy { |json| JSON.parse(json) == expected })
    end

    context 'with update_expected' do
      subject(:instance) do
        build_instance({
                         'sessions' => [{ 'suite' => suite_id }],
                         'steps' => [],
                         'comparison_config' => { 'expected_results_file' => expected_file }
                       }, base_options.merge(update_expected: true))
      end

      let(:results) { [{ 'test_id' => 'test-1', 'result' => 'fail' }] }

      before { allow(File).to receive(:write).with(expected_file, anything) }

      it 'overwrites the expected file with pretty-printed results and returns true on a mismatch' do
        allow(File).to receive(:exist?).with(expected_file).and_return(true)
        allow(File).to receive(:read).with(expected_file)
          .and_return(JSON.pretty_generate([{ 'test_id' => 'test-1', 'result' => 'pass' }]))
        allow(mock_compare).to receive_messages(results_match?: false, session_results: results)
        allow(mock_compare).to receive(:save_actual_results_to_file)
        allow(mock_compare).to receive(:save_comparison_csv_to_file)

        expect(instance.send(:compare_session, session)).to be(true)
        expect(File).to have_received(:write).with(expected_file, "#{JSON.pretty_generate(results)}\n")
        expect(mock_compare).to_not have_received(:save_actual_results_to_file)
        expect(mock_compare).to_not have_received(:save_comparison_csv_to_file)
      end

      it 'does not rewrite the expected file when its stored content would not change' do
        allow(File).to receive(:exist?).with(expected_file).and_return(true)
        allow(File).to receive(:read).with(expected_file).and_return("#{JSON.pretty_generate(results)}\n")
        allow(mock_compare).to receive_messages(results_match?: true, session_results: results)

        expect(instance.send(:compare_session, session)).to be(true)
        expect(File).to_not have_received(:write)
      end

      it 'keeps the fields of comparisons turned off on the command line when updating' do
        io_results = [{ 'test_id' => 'test-1', 'result' => 'pass',
                        'outputs' => [{ 'name' => 'token', 'value' => 'abc' }] }]
        instance = build_instance({
                                    'sessions' => [{ 'suite' => suite_id }],
                                    'steps' => [],
                                    'comparison_config' => { 'expected_results_file' => expected_file }
                                  }, base_options.merge(update_expected: true, compare_io: false))
        allow(File).to receive(:exist?).with(expected_file).and_return(true)
        allow(File).to receive(:read).with(expected_file).and_return("#{JSON.pretty_generate(io_results)}\n")
        allow(mock_compare).to receive_messages(results_match?: true, session_results: io_results)

        expect(instance.send(:compare_session, session)).to be(true)
        expect(File).to_not have_received(:write)
      end

      it 'rewrites the expected file when results match but its stored content would change' do
        old_format = [{ 'test_id' => 'test-1', 'result' => 'fail', 'test_session_id' => 'old-id',
                        'created_at' => '2026-01-01T00:00:00Z' }]
        allow(File).to receive(:exist?).with(expected_file).and_return(true)
        allow(File).to receive(:read).with(expected_file).and_return(JSON.pretty_generate(old_format))
        allow(mock_compare).to receive_messages(results_match?: true, session_results: results)
        allow(mock_compare).to receive(:save_actual_results_to_file)

        expect(instance.send(:compare_session, session)).to be(true)
        expect(File).to have_received(:write).with(expected_file, "#{JSON.pretty_generate(results)}\n")
        expect(mock_compare).to_not have_received(:save_actual_results_to_file)
      end

      it 'writes the expected file and returns true when it does not exist' do
        allow(File).to receive(:exist?).with(expected_file).and_return(false)
        allow(mock_results).to receive(:results_for_session).with(session_id).and_return(results)

        expect(instance.send(:compare_session, session)).to be(true)
        expect(File).to have_received(:write).with(expected_file, "#{JSON.pretty_generate(results)}\n")
      end
    end
  end

  describe '#compare_options' do
    let(:base_config) { { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] } }
    let(:session_id_rule) { { 'pattern' => session_id, 'replacement' => "<#{suite_id}.session_id>" } }

    let(:compare_class) { Inferno::CLI::Session::SessionCompare }
    let(:base_url_rule) do
      { 'patterns' => compare_class.inferno_base_url_patterns(inferno_host), 'replacement' => '<inferno_base_url>' }
    end
    let(:default_rules) { [base_url_rule, compare_class::TIMESTAMP_NORMALIZATION] }
    let(:hex_rule) { compare_class::RANDOM_64_CHAR_HEX_NORMALIZATION }

    it 'passes compare_requests through from the CLI options' do
      instance = build_instance(base_config, base_options.merge(compare_requests: true))
      expect(instance.send(:compare_options, '/tmp/expected.json')[:compare_requests]).to be(true)
    end

    it 'passes compare_io through from the CLI options' do
      instance = build_instance(base_config, base_options.merge(compare_io: true))
      expect(instance.send(:compare_options, '/tmp/expected.json')[:compare_io]).to be(true)
    end

    it 'includes the session id and default normalizations when normalized_strings is not in YAML' do
      instance = build_instance(base_config)
      opts = instance.send(:compare_options, '/tmp/expected.json')
      expect(opts[:normalized_strings])
        .to eq([session_id_rule] + default_rules + [hex_rule])
    end

    it 'reads normalized_strings from comparison_config, after the session id and default normalizations' do
      config = base_config.merge('comparison_config' => { 'normalized_strings' => ['http://new.server.com'] })
      instance = build_instance(config)
      opts = instance.send(:compare_options, '/tmp/expected.json')
      expect(opts[:normalized_strings]).to eq([session_id_rule] + default_rules + ['http://new.server.com', hex_rule])
    end

    [false, 'false', 'FALSE'].each do |value|
      it "omits the default normalizations when default_normalizations is #{value.inspect}" do
        config = base_config.merge('comparison_config' => { 'default_normalizations' => value })
        instance = build_instance(config)
        opts = instance.send(:compare_options, '/tmp/expected.json')
        expect(opts[:normalized_strings]).to eq([session_id_rule])
      end
    end

    it 'normalizes the base URL without a trailing slash' do
      instance = build_instance(base_config, base_options.merge(inferno_base_url: "#{inferno_host}/"))
      opts = instance.send(:compare_options, '/tmp/expected.json')
      expect(opts[:normalized_strings]).to include(base_url_rule)
    end

    it 'lets declared rules match placeholders from the session id and default normalizations' do
      rule = { 'pattern' => "/<inferno_base_url>\\/custom\\/<#{suite_id}.session_id>\\/resume\\?token=\\w+/",
               'replacement' => '<RESUME_URL>' }
      config = base_config.merge('comparison_config' => { 'normalized_strings' => [rule] })
      instance = build_instance(config)
      normalized_strings = instance.send(:compare_options, '/tmp/expected.json')[:normalized_strings]

      url = "#{inferno_host}/custom/#{session_id}/resume?token=abc123"
      expect(Inferno::CLI::Session::SessionCompare.normalize_string("resume at #{url}", normalized_strings))
        .to eq('resume at <RESUME_URL>')
    end

    it 'applies the random hex rule after declared rules so they can match the raw value' do
      rule = { 'pattern' => '/token=[0-9a-f]{64}/', 'replacement' => 'token=<TOKEN>' }
      config = base_config.merge('comparison_config' => { 'normalized_strings' => [rule] })
      normalized_strings = build_instance(config).send(:compare_options, '/tmp/expected.json')[:normalized_strings]
      hex64 = SecureRandom.hex(32)

      expect(Inferno::CLI::Session::SessionCompare.normalize_string("token=#{hex64} id=#{hex64}", normalized_strings))
        .to eq('token=<TOKEN> id=<RANDOM_64_CHAR_HEX>')
    end

    %w[compare_messages compare_result_message compare_requests compare_io].each do |option|
      it "turns off #{option} when comparison_config sets it to false, even when the CLI enables it" do
        config = base_config.merge('comparison_config' => { option => false })
        instance = build_instance(config, base_options.merge(option.to_sym => true))
        expect(instance.send(:compare_options, '/tmp/expected.json', suite_id)[option.to_sym]).to be(false)
      end
    end

    it 'does not turn on a comparison the CLI turns off when comparison_config sets it to true' do
      config = base_config.merge('comparison_config' => { 'compare_requests' => true })
      instance = build_instance(config, base_options.merge(compare_requests: false))
      expect(instance.send(:compare_options, '/tmp/expected.json', suite_id)[:compare_requests]).to be(false)
    end

    it "accepts 'false' strings in comparison_config" do
      config = base_config.merge('comparison_config' => { 'compare_io' => 'False' })
      expect(build_instance(config).send(:compare_options, '/tmp/expected.json', suite_id)[:compare_io]).to be(false)
    end

    it 'turns off a comparison for only the session whose comparison_config sets it to false' do
      config = {
        'sessions' => [{ 'suite' => suite_id, 'name' => 'receiver' }, { 'suite' => suite_id, 'name' => 'sender' }],
        'steps' => [],
        'comparison_config' => { 'sessions' => { 'sender' => { 'compare_requests' => false } } }
      }
      instance = build_instance(config, session_ids: %w[receiver-id sender-id])
      expect(instance.send(:compare_options, '/tmp/expected.json', 'sender')[:compare_requests]).to be(false)
      expect(instance.send(:compare_options, '/tmp/expected.json', 'receiver')[:compare_requests]).to be(true)
    end

    it "lets a session's setting turn on a comparison the script turns off" do
      config = multi_session_config({ 'compare_requests' => false,
                                      'sessions' => { 'sender' => { 'compare_requests' => true } } })
      instance = build_instance(config, session_ids: %w[receiver-id sender-id])
      expect(instance.send(:compare_options, '/tmp/expected.json', 'sender')).to include(compare_requests: true,
                                                                                         omitted_fields: [])
      expect(instance.send(:compare_options, '/tmp/expected.json', 'receiver'))
        .to include(compare_requests: false, omitted_fields: ['requests'])
    end

    it 'reads the settings of a session with a numeric name' do
      config = {
        'sessions' => [{ 'suite' => suite_id, 'name' => 1 }, { 'suite' => suite_id, 'name' => 2 }],
        'steps' => [],
        'comparison_config' => { 'sessions' => { 1 => { 'compare_io' => false } } }
      }
      instance = build_instance(config, session_ids: %w[one-id two-id])
      expect(instance.send(:compare_options, '/tmp/expected.json', '1')[:compare_io]).to be(false)
      expect(instance.send(:compare_options, '/tmp/expected.json', '2')[:compare_io]).to be(true)
    end

    it 'omits the fields of comparisons the script turns off from stored results' do
      config = base_config.merge('comparison_config' => { 'compare_io' => false, 'compare_requests' => 'false' })
      opts = build_instance(config).send(:compare_options, '/tmp/expected.json', suite_id)
      expect(opts[:omitted_fields]).to contain_exactly('requests', 'inputs', 'outputs')
    end

    it 'does not omit the fields of comparisons the command line turns off from stored results' do
      instance = build_instance(base_config, base_options.merge(compare_io: false, compare_requests: false))
      expect(instance.send(:compare_options, '/tmp/expected.json', suite_id)[:omitted_fields]).to eq([])
    end

    it 'passes the expected_file through as expected_results_file' do
      instance = build_instance(base_config)
      opts = instance.send(:compare_options, '/tmp/my_expected.json')
      expect(opts[:expected_results_file]).to eq('/tmp/my_expected.json')
    end
  end

  describe '#resolve_expected_file_for_comparison' do
    let(:session_details_url) { "#{inferno_host}/api/test_sessions/#{session_id}" }
    let(:session_data_url) { "#{inferno_host}/api/test_sessions/#{session_id}/session_data" }

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
        .to_return(status: 200, body: { 'test_suite' => {} }.to_json)
      stub_request(:get, session_data_url)
        .to_return(status: 200, body: [{ 'name' => 'url', 'value' => 'https://example.com' }].to_json)

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
        .to_return(status: 200, body: { 'test_suite' => {} }.to_json)
      stub_request(:get, session_data_url)
        .to_return(status: 200, body: [{ 'name' => 'url', 'value' => 'http://example.com' }].to_json)

      expect(instance.send(:resolve_expected_file_for_comparison, session)).to end_with('alt_expected.json')
    end
  end

  describe '#session_detail_condition_matches?' do
    subject(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    it 'matches an input by name from session inputs' do
      session_inputs = [{ 'name' => 'url', 'value' => 'http://example.com' }]
      cond = { 'field' => 'inputs.url', 'matches' => '^http://' }
      expect(instance.send(:session_detail_condition_matches?, cond, {}, session_inputs)).to be true
    end

    it 'does not match when the input value does not satisfy the pattern' do
      session_inputs = [{ 'name' => 'url', 'value' => 'https://example.com' }]
      cond = { 'field' => 'inputs.url', 'matches' => '^http://' }
      expect(instance.send(:session_detail_condition_matches?, cond, {}, session_inputs)).to be false
    end

    it 'does not match when the named input is absent' do
      session_inputs = [{ 'name' => 'other', 'value' => 'http://example.com' }]
      cond = { 'field' => 'inputs.url', 'matches' => '^http://' }
      expect(instance.send(:session_detail_condition_matches?, cond, {}, session_inputs)).to be false
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
      expect(instance.send(:session_detail_condition_matches?, cond, details, [])).to be true
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
      expect(instance.send(:session_detail_condition_matches?, cond, details, [])).to be false
    end

    it 'does not match configuration_messages when the array is empty' do
      details = { 'test_suite' => { 'configuration_messages' => [] } }
      cond = { 'field' => 'configuration_messages', 'matches' => '.*' }
      expect(instance.send(:session_detail_condition_matches?, cond, details, [])).to be false
    end

    it 'matches using not_matches when no message matches the pattern' do
      details = { 'test_suite' => { 'configuration_messages' => [{ 'type' => 'info', 'message' => 'All good' }] } }
      cond = { 'field' => 'configuration_messages', 'not_matches' => 'unavailable' }
      expect(instance.send(:session_detail_condition_matches?, cond, details, [])).to be true
    end

    it 'does not match using not_matches when any message matches the pattern' do
      details = {
        'test_suite' => {
          'configuration_messages' => [{ 'type' => 'error', 'message' => 'Validator service unavailable' }]
        }
      }
      cond = { 'field' => 'configuration_messages', 'not_matches' => 'unavailable' }
      expect(instance.send(:session_detail_condition_matches?, cond, details, [])).to be false
    end

    it 'matches an input using not_matches when the value does not match the pattern' do
      session_inputs = [{ 'name' => 'url', 'value' => 'https://example.com' }]
      cond = { 'field' => 'inputs.url', 'not_matches' => '^http://' }
      expect(instance.send(:session_detail_condition_matches?, cond, {}, session_inputs)).to be true
    end

    it 'matches inferno_base_url against the configured base URL' do
      cond = { 'field' => 'inferno_base_url', 'matches' => 'inferno\.example\.com' }
      expect(instance.send(:session_detail_condition_matches?, cond, {}, [])).to be true
    end

    it 'does not match inferno_base_url when the pattern does not match' do
      cond = { 'field' => 'inferno_base_url', 'matches' => 'other\.example\.com' }
      expect(instance.send(:session_detail_condition_matches?, cond, {}, [])).to be false
    end

    it 'matches inferno_base_url using not_matches' do
      cond = { 'field' => 'inferno_base_url', 'not_matches' => 'other\.example\.com' }
      expect(instance.send(:session_detail_condition_matches?, cond, {}, [])).to be true
    end

    it 'matches inferno_base_url without a trailing slash, as used in {inferno_base_url}' do
      slash_instance = build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] },
                                      base_options.merge(inferno_base_url: "#{inferno_host}/"))
      cond = { 'field' => 'inferno_base_url', 'matches' => "^#{Regexp.escape(inferno_host)}$" }
      expect(slash_instance.send(:session_detail_condition_matches?, cond, {}, [])).to be true
    end

    it 'matches inferno_base_url against the configured base_url when the option is not given' do
      configured_base_url = Inferno::Application['base_url'].to_s.delete_suffix('/')
      stub_request(:get, "#{configured_base_url}/api/test_suites")
        .to_return(status: 200, body: [{ 'id' => suite_id, 'title' => suite_id }].to_json)
      stub_request(:post, "#{configured_base_url}/api/test_sessions")
        .to_return(status: 200, body: session_response.to_json)
      default_instance = build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] },
                                        base_options.except(:inferno_base_url))
      cond = { 'field' => 'inferno_base_url', 'matches' => "^#{Regexp.escape(configured_base_url)}$" }
      expect(default_instance.send(:session_detail_condition_matches?, cond, {}, [])).to be true
    end

    it 'returns false for unsupported field names' do
      cond = { 'field' => 'test_suite_id', 'matches' => 'my_' }
      expect(instance.send(:session_detail_condition_matches?, cond, { 'test_suite_id' => 'my_suite' }, [])).to be false
    end

    it 'returns false when field is missing from condition' do
      cond = { 'matches' => 'my_' }
      expect(instance.send(:session_detail_condition_matches?, cond, {}, [])).to be false
    end

    it 'returns false when both matches and not_matches are missing from condition' do
      cond = { 'field' => 'inputs.url' }
      expect(instance.send(:session_detail_condition_matches?, cond, {}, [])).to be false
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
      expect(instance.execution_status.cancel_pending).to be true
      expect(a_request(:delete, "#{inferno_host}/api/test_runs/#{run_id}")).to have_been_made
    end

    it 'returns command nil without matching steps once a cancel is pending' do
      cancelled_group_id = 'cancelled-group'
      config = {
        'sessions' => [{ 'suite' => suite_id }],
        'steps' => [
          { 'status' => 'done', 'last_completed' => cancelled_group_id,
            'start_run' => { 'runnable' => 'next-group' } }
        ]
      }
      instance = build_instance(config)
      instance.execution_status.cancel_pending = true
      status = { 'status' => 'done', 'test_group_id' => cancelled_group_id }

      result = instance.send(:handle_actionable_status, status, instance.send(:sessions).first, timeout)
      expect(result).to eq({ command: nil, timeout: timeout, next_poll_session: nil })
    end
  end

  describe '#validate_commands_allowed!' do
    let(:config_with_command) do
      { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [{ 'command' => 'bundle exec ruby my_script.rb' }] }
    end

    it 'exits 1 with an error when the script has command steps but --allow-commands is not set' do
      expect do
        expect { build_instance(config_with_command, base_options.merge(allow_commands: false)) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
      end.to output(/allow-commands/).to_stdout
    end

    it 'does not exit when the script has command steps and --allow-commands is set' do
      expect { build_instance(config_with_command, base_options.merge(allow_commands: true)) }.to_not raise_error
    end

    it 'does not exit when the script has no command steps and --allow-commands is not set' do
      config = { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }
      expect { build_instance(config, base_options.merge(allow_commands: false)) }.to_not raise_error
    end
  end

  describe '#validate_step_commands!' do
    def config_with_step(step)
      { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [step] }
    end

    it 'exits 1 when a step has none of start_run, action, http_get, or command' do
      expect do
        expect { build_instance(config_with_step({ 'status' => 'done', 'last_completed' => '1.01' })) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
      end.to output(/Step 1 \(status: done, last_completed: 1\.01\) must have exactly one of .*found: none/).to_stdout
    end

    it 'exits 1 when a step has more than one of start_run, action, http_get, or command' do
      step = { 'status' => 'waiting', 'last_completed' => '1.02', 'action' => 'NOOP', 'command' => 'echo hi' }
      expect do
        expect { build_instance(config_with_step(step)) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
      end.to output(/found: action, command/).to_stdout
    end

    it 'exits 1 when a step is not a mapping' do
      { 'NOOP' => 'String', ['action', 'NOOP'] => 'Array' }.each do |step, type|
        expect do
          expect { build_instance(config_with_step(step)) }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
        end.to output(/Step 1 must be a mapping of step keys; found a #{type}\./).to_stdout
      end
    end

    it 'reports a mixed step instead of the --allow-commands error' do
      step = { 'status' => 'waiting', 'last_completed' => '1.02', 'http_get' => 'http://x', 'command' => 'echo hi' }
      expect do
        expect { build_instance(config_with_step(step), base_options.merge(allow_commands: false)) }
          .to raise_error(SystemExit)
      end.to output(satisfy { |out| out.include?('exactly one of') && !out.include?('allow-commands') }).to_stdout
    end

    it 'does not exit when each step has exactly one' do
      config = {
        'sessions' => [{ 'suite' => suite_id }],
        'steps' => [
          { 'status' => 'created', 'start_run' => nil },
          { 'status' => 'waiting', 'last_completed' => '1.01', 'http_get' => 'http://x' },
          { 'status' => 'waiting', 'last_completed' => '1.02', 'action' => 'wait' },
          { 'status' => 'done', 'last_completed' => '1.03', 'action' => 'END_SCRIPT' }
        ]
      }
      expect { build_instance(config) }.to_not raise_error
    end

    def step_config(step)
      { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [{ 'status' => 'done' }.merge(step)] }
    end

    [nil, 'ls', 5].each do |action|
      it "exits 1 when a step's action is #{action.inspect}" do
        expect_exit_with_error(step_config({ 'action' => action }),
                               /Step 1 .* has action \S*#{action}\S*; use END_SCRIPT, NOOP, WAIT/)
      end
    end

    %w[http_get command].each do |key|
      [nil, ''].each do |value|
        it "exits 1 when a step's #{key} is #{value.inspect}" do
          expect_exit_with_error(step_config({ key => value }), /Step 1 .* must have a value for #{key}/)
        end
      end
    end
  end

  describe '#validate_expected_files!' do
    let(:dir) { Dir.mktmpdir }
    let(:valid_condition) { { 'field' => 'inferno_base_url', 'matches' => 'x' } }

    after { FileUtils.remove_entry(dir) }

    def expected_path(name, content = nil)
      File.join(dir, name).tap { |path| File.write(path, content) if content }
    end

    def config_with_expected(expected_file, alternate_file = nil)
      comparison_config = { 'expected_results_file' => expected_file }
      if alternate_file
        comparison_config['alternate_expected_files'] = [{ 'file' => alternate_file, 'when' => [valid_condition] }]
      end
      { 'sessions' => [{ 'suite' => suite_id }], 'steps' => [], 'comparison_config' => comparison_config }
    end

    def config_with_alternate(alternate)
      config_with_expected(expected_path('expected.json', '[]')).tap do |config|
        config['comparison_config']['alternate_expected_files'] = [alternate]
      end
    end

    it 'exits 1 when an expected file does not hold a JSON array of results' do
      file = expected_path('expected.json', { 'matched' => true, 'results' => [] }.to_json)
      expect_exit_with_error(config_with_expected(file),
                             /'#{Regexp.escape(file)}' must contain a JSON array of results.*Fix or delete/)
    end

    it 'exits 1 when an alternate expected file is not valid JSON' do
      alternate = expected_path('alternate.json', 'not json')
      expect_exit_with_error(config_with_expected(expected_path('expected.json', '[]'), alternate),
                             /'#{Regexp.escape(alternate)}' is not valid JSON/)
    end

    it 'exits 1 when an alternate expected file entry has no file' do
      expect_exit_with_error(config_with_alternate({ 'when' => [valid_condition] }),
                             /Alternate expected file 1 for session '#{suite_id}' must have a file\./)
    end

    [nil, [], { 'field' => 'inferno_base_url', 'matches' => 'x' }].each do |when_value|
      it "exits 1 when an alternate expected file entry's when is #{when_value.inspect}" do
        expect_exit_with_error(config_with_alternate({ 'file' => 'alt.json', 'when' => when_value }),
                               /Alternate expected file 1 for session '#{suite_id}' must have a when list/)
      end
    end

    {
      'a condition that is not a mapping' => ['inferno_base_url', /must be a mapping with field and matches/],
      'a condition with no field' => [{ 'matches' => 'x' }, /has unsupported field ''/],
      'a condition with an unsupported field' =>
        [{ 'field' => 'test_suite_id', 'matches' => 'x' }, /has unsupported field 'test_suite_id'; use inputs/],
      'a condition with an empty input name' => [{ 'field' => 'inputs.', 'matches' => 'x' },
                                                 /has unsupported field 'inputs\.'/],
      'a condition with no pattern' =>
        [{ 'field' => 'inferno_base_url' }, /must have matches, not_matches, or both/],
      'a condition with a number pattern' =>
        [{ 'field' => 'inferno_base_url', 'matches' => 37_800 }, /has a matches value that is not a string; quote/],
      'a condition with a boolean pattern' =>
        [{ 'field' => 'inferno_base_url', 'matches' => false }, /has a matches value that is not a string; quote/],
      'a condition with a blank pattern' =>
        [{ 'field' => 'inferno_base_url', 'matches' => '  ' }, /must have matches, not_matches, or both/],
      'a condition with a list pattern' =>
        [{ 'field' => 'inferno_base_url', 'not_matches' => %w[localhost 127.0.0.1] },
         /has a not_matches value that is not a string; quote/],
      'a condition with an invalid regex' =>
        [{ 'field' => 'inputs.url', 'not_matches' => '[' }, /has an invalid not_matches regex '\['/]
    }.each do |description, (condition, message)|
      it "exits 1 for #{description}" do
        expect_exit_with_error(config_with_alternate({ 'file' => 'alt.json', 'when' => [valid_condition, condition] }),
                               /Condition 2 of alternate expected file 1 for session '#{suite_id}' #{message.source}/)
      end
    end

    it 'reports every invalid alternate expected file entry' do
      config = config_with_alternate({ 'when' => [valid_condition] })
      config['comparison_config']['alternate_expected_files'] << { 'file' => 'alt.json',
                                                                   'when' => [{ 'field' => 'x' }] }
      expect_exit_with_error(config, /must have a file\..*Condition 1 of alternate expected file 2/)
    end

    it 'accepts every supported condition field' do
      conditions = [{ 'field' => 'inputs.url', 'matches' => '^http' },
                    { 'field' => 'configuration_messages', 'not_matches' => 'error' },
                    { 'field' => 'inferno_base_url', 'matches' => '4567' }]
      expect { build_instance(config_with_alternate({ 'file' => 'alt.json', 'when' => conditions })) }
        .to_not raise_error
    end

    it 'checks the expected files of every session in a multi-session script' do
      file = expected_path('sender.json', '[1, 2]')
      config = {
        'sessions' => [{ 'suite' => suite_id, 'name' => 'receiver' }, { 'suite' => suite_id, 'name' => 'sender' }],
        'steps' => [],
        'comparison_config' => { 'sessions' => { 'sender' => { 'expected_results_file' => file } } }
      }
      expect_exit_with_error(config, /'#{Regexp.escape(file)}' must contain a JSON array of results/)
    end

    it 'does not exit when expected files are valid or do not exist yet' do
      config = config_with_expected(expected_path('expected.json', [{ 'test_id' => 't', 'result' => 'pass' }].to_json),
                                    expected_path('missing.json'))
      expect { build_instance(config) }.to_not raise_error
    end
  end

  describe '#validate_comparison_settings!' do
    context 'with normalized_strings' do
      def expect_rule_error(rules, message)
        expect_exit_with_error(single_session_config({ 'normalized_strings' => rules }), message)
      end

      it 'exits 1 when normalized_strings is not a list' do
        expect_rule_error({ 'pattern' => 'x' }, /comparison_config.normalized_strings must be a list of rules/)
      end

      it 'exits 1 for an invalid regex' do
        expect_rule_error(['/code=[A-Z/'],
                          %r{Rule 1 of comparison_config.normalized_strings has an invalid regex '/code=\[A-Z/'})
      end

      it 'exits 1 for an invalid regex in a patterns list' do
        expect_rule_error(['ok', { 'patterns' => ['fine', '/(/'] }], /Rule 2 .* has an invalid regex/)
      end

      it 'exits 1 for an empty pattern' do
        expect_rule_error([''], /Rule 1 .* has an empty pattern/)
      end

      [true, nil, ['x']].each do |rule|
        it "exits 1 for a #{rule.inspect} rule" do
          expect_rule_error([rule], /Rule 1 .* has a pattern that is not a string/)
        end
      end

      it 'exits 1 for unknown rule keys' do
        expect_rule_error([{ 'pattern' => 'x', 'replace' => 'y' }], /Rule 1 .* has unknown keys replace/)
      end

      [{ 'replacement' => 'y' }, { 'pattern' => 'x', 'patterns' => ['y'] }].each do |rule|
        it "exits 1 for a rule with #{rule.keys.join(' and ')}" do
          expect_rule_error([rule], /Rule 1 .* must have pattern or patterns, not both/)
        end
      end

      [[], 'x'].each do |patterns|
        it "exits 1 when patterns is #{patterns.inspect}" do
          expect_rule_error([{ 'patterns' => patterns }], /Rule 1 .* must have a list of patterns/)
        end
      end

      it 'exits 1 for a replacement that is not a string' do
        expect_rule_error([{ 'pattern' => 'x', 'replacement' => 1 }],
                          /Rule 1 .* has a replacement that is not a string/)
      end

      it 'does not exit for valid rules' do
        rules = ['plain', 4567, '/code=\\w+/i', { 'pattern' => '/a/', 'replacement' => '<A>' },
                 { 'patterns' => ['b', '/c/'] }]
        expect { build_instance(single_session_config({ 'normalized_strings' => rules })) }.to_not raise_error
      end
    end

    it 'exits 1 for an unknown compare_ setting' do
      expect_exit_with_error(single_session_config({ 'compare_request' => false }),
                             /comparison_config has unknown setting 'compare_request'; use .*compare_requests/)
    end

    [0, 'no', 'off', ['false']].each do |value|
      it "exits 1 when a comparison setting is #{value.inspect}" do
        expect_exit_with_error(single_session_config({ 'compare_requests' => value }),
                               /comparison_config.compare_requests must be true or false/)
      end
    end

    it 'exits 1 when default_normalizations is not a boolean' do
      expect_exit_with_error(single_session_config({ 'default_normalizations' => 'no' }),
                             /comparison_config.default_normalizations must be true or false/)
    end

    it 'exits 1 for an unknown setting that does not start with compare_' do
      expect_exit_with_error(single_session_config({ 'default_normalization' => false }),
                             /comparison_config has unknown setting 'default_normalization'/)
    end

    ['none', ['compare_requests']].each do |value|
      it "exits 1 when comparison_config is #{value.inspect}" do
        expect_exit_with_error(single_session_config(value), /comparison_config must be a mapping/)
      end
    end

    %w[expected_results_file alternate_expected_files].each do |key|
      it "exits 1 for #{key} directly under comparison_config in a multi-session script" do
        expect_exit_with_error(multi_session_config({ key => 'expected.json' }),
                               /comparison_config.#{key} is set for each session.*comparison_config.sessions/)
      end
    end

    %w[default_normalizations normalized_strings].each do |key|
      it "exits 1 for #{key} in a session's settings" do
        config = multi_session_config({ 'sessions' => { 'sender' => { key => false } } })
        expect_exit_with_error(config, /comparison_config.sessions.sender.#{key} applies to the whole script/)
      end
    end

    it 'exits 1 when sessions has more than one entry for a session' do
      config = {
        'sessions' => [{ 'suite' => suite_id, 'name' => 1 }, { 'suite' => suite_id, 'name' => 2 }],
        'steps' => [],
        'comparison_config' => { 'sessions' => { 1 => { 'compare_io' => false }, '1' => { 'compare_io' => true } } }
      }
      expect_exit_with_error(config, /comparison_config.sessions has more than one entry for session '1'/)
    end

    it 'exits 1 when sessions is used in a single-session script' do
      config = single_session_config({ 'sessions' => { suite_id => { 'compare_requests' => false } } })
      expect_exit_with_error(config, /comparison_config.sessions is only used in multi-session scripts/)
    end

    it 'exits 1 when sessions is not a mapping' do
      expect_exit_with_error(multi_session_config({ 'sessions' => ['sender'] }),
                             /comparison_config.sessions must be a mapping/)
    end

    it 'exits 1 when a sessions entry does not match a session in the script' do
      config = multi_session_config({ 'sessions' => { 'sendr' => { 'compare_requests' => false } } })
      expect_exit_with_error(config, /comparison_config.sessions.sendr does not match a session.*receiver, sender/)
    end

    it 'exits 1 when a sessions entry is not a mapping' do
      expect_exit_with_error(multi_session_config({ 'sessions' => { 'sender' => 'compare_requests' } }),
                             /comparison_config.sessions.sender must be a mapping of settings/)
    end

    it "exits 1 for an invalid setting in a session's settings" do
      config = multi_session_config({ 'sessions' => { 'sender' => { 'compare_io' => 'off', 'compare_ios' => true } } })
      expect_exit_with_error(config,
                             /sessions.sender has unknown setting 'compare_ios'.*sessions.sender.compare_io must/)
    end

    it 'does not exit for valid settings' do
      config = multi_session_config({ 'compare_requests' => 'False', 'default_normalizations' => true,
                                      'normalized_strings' => ['x'],
                                      'sessions' => { 'sender' => { 'compare_requests' => true,
                                                                    'expected_results_file' => 'sender.json' },
                                                      'receiver' => nil } })
      expect { build_instance(config, session_ids: %w[receiver-id sender-id]) }.to_not raise_error
    end

    it 'does not exit for expected file settings directly under comparison_config in a single-session script' do
      config = single_session_config({ 'expected_results_file' => 'expected.json', 'normalized_strings' => ['x'] })
      expect { build_instance(config) }.to_not raise_error
    end
  end

  describe '#validate_session_names!' do
    it 'exits 1 when a session name contains whitespace' do
      config = { 'sessions' => [{ 'suite' => suite_id, 'name' => 'my receiver' }], 'steps' => [] }
      expect_exit_with_error(config, /Session name 'my receiver' must not contain whitespace/)
    end

    it "exits 1 when a session name contains '.'" do
      config = { 'sessions' => [{ 'suite' => suite_id, 'name' => 'my.receiver' }], 'steps' => [] }
      expect_exit_with_error(config, /Session name 'my\.receiver' must not contain/)
    end

    it 'exits 1 when two sessions have the same name' do
      config = {
        'sessions' => [{ 'suite' => suite_id, 'name' => 'receiver' }, { 'suite' => 'other', 'name' => 'receiver' }],
        'steps' => []
      }
      expect_exit_with_error(config, /Duplicate session name 'receiver'/)
    end

    it 'exits 1 when a session in a multi-session script has no name' do
      config = { 'sessions' => [{ 'suite' => suite_id, 'name' => 'sender' }, { 'suite' => suite_id }], 'steps' => [] }
      expect_exit_with_error(config, /Session for suite '#{suite_id}' must have a name/)
    end

    it 'does not exit when the only session has no name, even if the suite is a title' do
      config = { 'sessions' => [{ 'suite' => 'Demonstration Suite' }], 'steps' => [] }
      allow_any_instance_of(Inferno::CLI::Session::CreateSession).to receive(:suite_id).and_return(suite_id)
      expect { build_instance(config) }.to_not raise_error
    end

    it 'does not exit for unique, valid session names' do
      config = {
        'sessions' => [{ 'suite' => suite_id, 'name' => 'sender' }, { 'suite' => suite_id, 'name' => 'receiver-2' }],
        'steps' => []
      }
      expect { build_instance(config) }.to_not raise_error
    end

    it 'resolves tokens for numeric session names' do
      config = {
        'sessions' => [{ 'suite' => suite_id, 'name' => 1 }, { 'suite' => suite_id, 'name' => 2 }],
        'steps' => []
      }
      instance = build_instance(config)
      expect(instance.send(:apply_templates, '{1.session_id}', {}, '2')).to eq(session_id)
    end
  end

  describe '#execute_command' do
    subject(:instance) do
      build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] },
                     base_options.merge(allow_commands: true))
    end

    it 'returns true when the command succeeds' do
      expect(instance.send(:execute_command, 'true')).to be true
    end

    it 'returns false when the command fails' do
      expect(instance.send(:execute_command, 'false')).to be false
    end
  end

  describe '#execute_http_get' do
    let(:instance) { build_instance({ 'sessions' => [{ 'suite' => suite_id }], 'steps' => [] }) }

    let(:url) { "#{inferno_host}/custom/demo/resume?token=abc" }

    it 'sends a GET request and returns true on success' do
      request = stub_request(:get, url).to_return(status: 200)
      expect(instance.send(:execute_http_get, url)).to be true
      expect(request).to have_been_made
    end

    it 'returns true and logs a warning on an error response' do
      stub_request(:get, url).to_return(status: 500)
      allow(instance).to receive(:warn)
      expect(instance.send(:execute_http_get, url)).to be true
      expect(instance).to have_received(:warn).with(/HTTP 500/)
    end

    it 'returns true without a warning on a redirect response (e.g., from a resume route)' do
      stub_request(:get, url).to_return(status: 302, headers: { 'Location' => "#{inferno_host}/demo" })
      allow(instance).to receive(:warn)
      expect(instance.send(:execute_http_get, url)).to be true
      expect(instance).to_not have_received(:warn)
    end

    it 'returns false when the request cannot be made' do
      stub_request(:get, url).to_raise(Faraday::ConnectionFailed.new('connection refused'))
      allow(instance).to receive(:warn)
      expect(instance.send(:execute_http_get, url)).to be false
      expect(instance).to have_received(:warn).with(/connection refused/)
    end

    it 'returns false without making a request for a non-http(s) URL' do
      allow(instance).to receive(:warn)
      expect(instance.send(:execute_http_get, 'file:///etc/passwd')).to be false
      expect(instance).to have_received(:warn).with(/must be http or https/)
    end

    it 'returns false for an unparseable URL' do
      allow(instance).to receive(:warn)
      expect(instance.send(:execute_http_get, 'http://exa mple.com')).to be false
      expect(instance).to have_received(:warn).with(/failed/)
    end

    it 'uses the current step timeout for the request' do
      stub_request(:get, url).to_return(status: 200)
      allow(Faraday).to receive(:new).and_call_original
      instance.execution_status.current_timeout = 45
      instance.send(:execute_http_get, url)
      expect(Faraday).to have_received(:new).with(request: { timeout: 45 })
    end

    it 'returns false when the request times out' do
      stub_request(:get, url).to_timeout
      allow(instance).to receive(:warn)
      expect(instance.send(:execute_http_get, url)).to be false
      expect(instance).to have_received(:warn).with(/http_get request to .* failed/)
    end
  end

  describe 'http_get steps' do
    let(:url) { "#{inferno_host}/custom/demo/resume" }
    let(:config) do
      {
        'sessions' => [{ 'suite' => suite_id }],
        'steps' => [{ 'status' => 'waiting', 'last_completed' => 'wait-test', 'http_get' => '{wait_outputs.url}' }]
      }
    end
    let(:status) do
      { 'status' => 'waiting', 'last_test_executed' => 'wait-test',
        'wait_outputs' => [{ 'name' => 'url', 'value' => url }] }
    end

    it 'does not require --allow-commands' do
      expect { build_instance(config, base_options.merge(allow_commands: false)) }.to_not raise_error
    end

    it 'resolves template tokens in the URL' do
      instance = build_instance(config)
      step = instance.send(:resolve_command, config['steps'].first, status, suite_id)
      expect(step).to eq({ command: 'HTTP_GET', url: })
    end

    it 'sends the GET request when the step is taken' do
      instance = build_instance(config)
      request = stub_request(:get, url).to_return(status: 200)
      instance.send(:take_step, { command: 'HTTP_GET', url: })
      expect(request).to have_been_made
      expect(instance.execution_status.failed).to be_falsey
    end

    it "uses the step's timeout for the request, falling back to the default poll timeout" do
      instance = build_instance(config)
      stub_request(:get, url).to_return(status: 200)
      allow(Faraday).to receive(:new).and_call_original

      instance.send(:take_step, { command: 'HTTP_GET', url:, timeout: 45 })
      expect(Faraday).to have_received(:new).with(request: { timeout: 45 })

      instance.send(:take_step, { command: 'HTTP_GET', url: })
      expect(Faraday).to have_received(:new).with(request: { timeout: base_options[:default_poll_timeout] })
    end

    it 'marks the script failed and done when the request cannot be made' do
      instance = build_instance(config)
      stub_request(:get, url).to_raise(Faraday::ConnectionFailed.new('connection refused'))
      instance.send(:take_step, { command: 'HTTP_GET', url: })
      expect(instance.execution_status.failed).to be true
      expect(instance.execution_status.done).to be true
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
      expect(instance.execution_status.cancel_pending).to be true
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
