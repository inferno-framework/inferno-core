require_relative '../../../../lib/inferno/apps/cli/session/start_run'

RSpec.describe Inferno::CLI::Session::StartRun do
  let(:session_id) { 'test-session-id' }
  let(:inferno_host) { 'https://inferno.healthit.gov/suites' }
  let(:options) { { inferno_base_url: inferno_host, runnable: 'suite' } }
  let(:session_details_url) { "#{inferno_host}/api/test_sessions/#{session_id}" }
  let(:session_data_url) { "#{inferno_host}/api/test_sessions/#{session_id}/session_data" }
  let(:test_runs_url) { "#{inferno_host}/api/test_runs" }

  let(:suite_id) { 'demo_suite' }
  let(:group_id) { "#{suite_id}-group_1" }
  let(:test_id) { "#{group_id}-test_1" }
  let(:run_response) { { 'id' => 'new-run-id', 'test_session_id' => session_id, 'status' => 'queued' } }

  # Minimal runnable tree: a suite containing one group, containing one test
  let(:suite_details) do
    {
      'id' => suite_id,
      'suite_summary' => 'Demo Suite',
      'short_id' => 'DS',
      'inputs' => [{ 'name' => 'url', 'type' => 'text' }],
      'test_groups' => [
        {
          'id' => group_id,
          'short_id' => '1',
          'run_as_group' => true,
          'inputs' => [{ 'name' => 'url', 'type' => 'text' }],
          'tests' => [
            {
              'id' => test_id,
              'short_id' => '1.01',
              'inputs' => [{ 'name' => 'url', 'type' => 'text' }]
            }
          ]
        }
      ]
    }
  end

  let(:session_details) do
    { 'id' => session_id, 'test_suite_id' => suite_id, 'test_suite' => suite_details }
  end

  let(:session_data) do
    [{ 'name' => 'url', 'value' => 'https://example.com/fhir', 'type' => 'text' }]
  end

  def stub_session_details(body: session_details.to_json, status: 200)
    stub_request(:get, session_details_url)
      .to_return(status:, body:)
  end

  def stub_session_data(body: session_data.to_json)
    stub_request(:get, session_data_url)
      .to_return(status: 200, body:)
  end

  describe '#run' do
    it 'runs the whole suite when runnable is "suite", outputs the run data, and exits 0' do
      stub_session_details
      stub_session_data
      run_request = stub_request(:post, test_runs_url)
        .with(body: hash_including(test_suite_id: suite_id))
        .to_return(status: 200, body: run_response.to_json)

      expect do
        expect { described_class.new(session_id, options.merge(runnable: 'suite')).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(run_response)}\n").to_stdout

      expect(run_request).to have_been_made.once
    end

    it 'exits 3 and prints an error when no runnable is given' do
      stub_session_details

      expected_error = { errors: 'No runnable specified. Use a group/test id or "suite" to run the whole suite.' }
      expect do
        expect { described_class.new(session_id, { inferno_base_url: inferno_host }).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{expected_error.to_json}\n").to_stdout
    end

    it 'runs a group when the runnable option is a suffix of a group id' do
      stub_session_details
      stub_session_data
      run_request = stub_request(:post, test_runs_url)
        .with(body: hash_including(test_group_id: group_id))
        .to_return(status: 200, body: run_response.to_json)

      expect do
        expect { described_class.new(session_id, options.merge(runnable: 'group_1')).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(run_response)}\n").to_stdout

      expect(run_request).to have_been_made.once
    end

    it 'runs a test when the runnable option matches a test short_id' do
      stub_session_details
      stub_session_data
      run_request = stub_request(:post, test_runs_url)
        .with(body: hash_including(test_id:))
        .to_return(status: 200, body: run_response.to_json)

      expect do
        expect { described_class.new(session_id, options.merge(runnable: '1.01')).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(run_response)}\n").to_stdout

      expect(run_request).to have_been_made.once
    end

    it 'uses user-supplied inputs to override session inputs' do
      stub_session_details
      stub_session_data
      run_request = stub_request(:post, test_runs_url)
        .with(body: hash_including(inputs: [{ 'name' => 'url', 'value' => 'https://user-supplied.com/fhir' }]))
        .to_return(status: 200, body: run_response.to_json)

      expect do
        expect { described_class.new(session_id, options.merge(inputs: { 'url' => 'https://user-supplied.com/fhir' })).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout

      expect(run_request).to have_been_made.once
    end

    it 'uses the input default value when session and user inputs are both absent' do
      suite_with_default = suite_details.merge(
        'inputs' => [{ 'name' => 'url', 'type' => 'text', 'default' => 'https://default.com/fhir' }]
      )
      stub_session_details(body: session_details.merge('test_suite' => suite_with_default).to_json)
      stub_session_data(body: [].to_json)
      run_request = stub_request(:post, test_runs_url)
        .with(body: hash_including(inputs: [{ 'name' => 'url', 'value' => 'https://default.com/fhir' }]))
        .to_return(status: 200, body: run_response.to_json)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout

      expect(run_request).to have_been_made.once
    end

    it 'exits 3 and prints an error when the runnable is not found in the suite' do
      stub_session_details
      unknown_options = options.merge(runnable: 'nonexistent_test')

      expected_error = { errors: "Runnable 'nonexistent_test' not found in suite '#{suite_id}'" }
      expect do
        expect { described_class.new(session_id, unknown_options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{expected_error.to_json}\n").to_stdout
    end

    it 'exits 3 and prints an error when the runnable matches more than one runnable' do
      duplicate_group = {
        'id' => "#{suite_id}-group_2",
        'short_id' => '2',
        'run_as_group' => true,
        'inputs' => [],
        'tests' => [
          { 'id' => "#{suite_id}-group_2-test_1", 'short_id' => '2.01', 'inputs' => [] }
        ]
      }
      suite_with_duplicates = suite_details.merge(
        'test_groups' => suite_details['test_groups'] + [duplicate_group]
      )
      stub_session_details(body: session_details.merge('test_suite' => suite_with_duplicates).to_json)

      # 'test_1' suffix matches both demo_suite-group_1-test_1 and demo_suite-group_2-test_1
      duplicate_options = options.merge(runnable: 'test_1')
      expected_error = { errors: "Runnable 'test_1' not unique in suite '#{suite_id}'" }
      expect do
        expect { described_class.new(session_id, duplicate_options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{expected_error.to_json}\n").to_stdout
    end

    it 'exits 3 and prints a not-found error when the session is not found' do
      stub_session_details(body: 'Not Found', status: 404)

      expected_error = { errors: "Session '#{session_id}' not found on Inferno host at '#{inferno_host}/'" }
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints the error body when the start run request fails with a server error' do
      stub_session_details
      stub_session_data
      error_body = { errors: 'Internal server error' }
      stub_request(:post, test_runs_url)
        .to_return(status: 500, body: error_body.to_json)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(error_body)}\n").to_stdout
    end

    context 'when an input value is a @file reference' do
      it 'reads the file content and uses it as the input value' do
        Tempfile.create(['input', '.json']) do |f|
          f.write('{"resourceType":"Coverage"}')
          f.flush

          stub_session_details
          stub_session_data(body: [{ 'name' => 'url', 'value' => '', 'type' => 'text' }].to_json)
          run_request = stub_request(:post, test_runs_url)
            .with(body: hash_including(inputs: [{ 'name' => 'url', 'value' => '{"resourceType":"Coverage"}' }]))
            .to_return(status: 200, body: run_response.to_json)

          expect do
            expect { described_class.new(session_id, options.merge(inputs: { 'url' => "@#{f.path}" })).run }
              .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
          end.to output(/.+/).to_stdout

          expect(run_request).to have_been_made.once
        end
      end

      it 'exits 3 and prints an error when the referenced file does not exist' do
        path = '/nonexistent/path/file.json'
        stub_session_details
        stub_session_data
        expected_error = { errors: "File input not found: #{path}" }

        expect do
          expect { described_class.new(session_id, options.merge(inputs: { 'url' => "@#{path}" })).run }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
        end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
      end
    end

    context 'when processing auth_info inputs' do
      let(:auth_input_name) { 'smart_credentials' }

      # Build session_details whose suite has a single auth_info input with given options,
      # stub all three endpoints, and return the run_request stub for further assertions.
      def stub_auth_info_run(expected_component, session_value: '', auth_input_options: {})
        auth_input = { 'name' => auth_input_name, 'type' => 'auth_info' }
        auth_input['options'] = auth_input_options unless auth_input_options.empty?

        details = session_details.merge('test_suite' => suite_details.merge('inputs' => [auth_input]))
        stub_session_details(body: details.to_json)
        session_entry = [{ 'name' => auth_input_name, 'value' => session_value, 'type' => 'auth_info' }]
        stub_session_data(body: session_entry.to_json)
        stub_request(:post, test_runs_url)
          .with(body: hash_including(inputs: [{ 'name' => auth_input_name, 'value' => expected_component.to_json }]))
          .to_return(status: 200, body: run_response.to_json)
      end

      it 'defaults auth_type to public when the component object is empty (access mode)' do
        # access mode is the default when options.mode is absent;
        # access mode component defaults (access_token, etc.) are all '' so none are set
        expected_component = { 'auth_type' => 'public' }
        run_request = stub_auth_info_run(expected_component)

        expect do
          expect { described_class.new(session_id, options).run }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
        end.to output(/.+/).to_stdout

        expect(run_request).to have_been_made.once
      end

      it 'applies auth mode defaults (use_discovery, pkce_support, etc.) when options.mode is auth' do
        expected_component = {
          'auth_type' => 'public',
          'use_discovery' => 'true',
          'pkce_support' => 'enabled',
          'pkce_code_challenge_method' => 'S256',
          'auth_request_method' => 'GET'
        }
        run_request = stub_auth_info_run(expected_component, auth_input_options: { 'mode' => 'auth' })

        expect do
          expect { described_class.new(session_id, options).run }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
        end.to output(/.+/).to_stdout

        expect(run_request).to have_been_made.once
      end

      it 'sets encryption_algorithm to ES384 when auth_type is backend_services' do
        session_value = { 'auth_type' => 'backend_services' }.to_json
        expected_component = { 'auth_type' => 'backend_services', 'encryption_algorithm' => 'ES384' }
        run_request = stub_auth_info_run(expected_component, session_value:)

        expect do
          expect { described_class.new(session_id, options).run }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
        end.to output(/.+/).to_stdout

        expect(run_request).to have_been_made.once
      end

      it 'sets encryption_algorithm to ES384 when auth_type is asymmetric' do
        session_value = { 'auth_type' => 'asymmetric' }.to_json
        expected_component = { 'auth_type' => 'asymmetric', 'encryption_algorithm' => 'ES384' }
        run_request = stub_auth_info_run(expected_component, session_value:)

        expect do
          expect { described_class.new(session_id, options).run }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
        end.to output(/.+/).to_stdout

        expect(run_request).to have_been_made.once
      end

      it 'applies component defaults defined in the runnable input options when the component is absent' do
        auth_input_options = { 'components' => [{ 'name' => 'client_id', 'default' => 'my-client-id' }] }
        # runnable component defaults are applied before built-in defaults, so client_id appears first
        expected_component = { 'client_id' => 'my-client-id', 'auth_type' => 'public' }
        run_request = stub_auth_info_run(expected_component, auth_input_options:)

        expect do
          expect { described_class.new(session_id, options).run }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
        end.to output(/.+/).to_stdout

        expect(run_request).to have_been_made.once
      end

      it 'does not override an existing component value with the runnable input options default' do
        session_value = { 'client_id' => 'existing-client-id' }.to_json
        auth_input_options = { 'components' => [{ 'name' => 'client_id', 'default' => 'my-client-id' }] }
        expected_component = { 'client_id' => 'existing-client-id', 'auth_type' => 'public' }
        run_request = stub_auth_info_run(expected_component, session_value:, auth_input_options:)

        expect do
          expect { described_class.new(session_id, options).run }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
        end.to output(/.+/).to_stdout

        expect(run_request).to have_been_made.once
      end
    end
  end
end
