require_relative '../../../../lib/inferno/apps/cli/session/create_session'

RSpec.describe Inferno::CLI::Session::CreateSession do
  let(:suite_id) { 'us_core_v610' }
  let(:inferno_host) { 'https://inferno.healthit.gov/suites' }
  let(:session_response) { { id: 'new-session-id', test_suite_id: suite_id } }
  let(:create_url) { "#{inferno_host}/api/test_sessions" }
  let(:options) { { inferno_base_url: inferno_host } }

  describe '#run' do
    it 'posts the suite_id, outputs the response as pretty-printed JSON, and exits 0' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id })
        .to_return(status: 200, body: session_response.to_json)

      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output("#{JSON.pretty_generate(session_response)}\n").to_stdout

      expect(create_request).to have_been_made.once
    end

    it 'includes preset_id in the request body when provided' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id, preset_id: 'my-preset' })
        .to_return(status: 200, body: session_response.to_json)

      expect do
        expect { described_class.new(suite_id, options.merge(preset_id: 'my-preset')).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout

      expect(create_request).to have_been_made.once
    end

    it 'transforms suite_options from a hash into an id/value array in the request body' do
      suite_opts = { 'us_core_version' => '6.1.0', 'smart_app_launch_version' => '2.0.0' }
      expected_opts_list = [
        { id: 'us_core_version', value: '6.1.0' },
        { id: 'smart_app_launch_version', value: '2.0.0' }
      ]
      suite_definition = {
        id: suite_id,
        suite_options: [
          { id: 'us_core_version', title: 'US Core Version' },
          { id: 'smart_app_launch_version', title: 'SMART App Launch Version' }
        ]
      }
      stub_request(:get, "#{inferno_host}/api/test_suites/#{suite_id}")
        .to_return(status: 200, body: suite_definition.to_json)
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id, suite_options: expected_opts_list })
        .to_return(status: 200, body: session_response.to_json)

      expect do
        expect { described_class.new(suite_id, options.merge(suite_options: suite_opts)).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout

      expect(create_request).to have_been_made.once
    end

    it 'exits 3 and prints a not-found error when the Inferno host is not found' do
      stub_request(:post, create_url)
        .to_return(status: 404, body: 'Not Found')

      expected_error = { errors: "Running Inferno host not found at '#{inferno_host}'" }
      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints a not-found error when the server returns a 404 with a non-JSON body' do
      stub_request(:post, create_url)
        .to_return(status: 404, body: '<html><body>404 Not Found</body></html>')

      expected_error = { errors: "Running Inferno host not found at '#{inferno_host}'" }
      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints a connection error when Inferno is not reachable' do
      stub_request(:post, create_url)
        .to_raise(Faraday::ConnectionFailed.new('Connection refused'))

      expected_error = { errors: "Could not connect to Inferno at '#{inferno_host}': Connection refused" }
      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints a connection error when the request times out' do
      stub_request(:post, create_url)
        .to_raise(Faraday::TimeoutError.new('timeout'))

      expected_error = { errors: "Could not connect to Inferno at '#{inferno_host}': timeout" }
      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints the error body when the create request fails with a server error' do
      error_body = { errors: 'Internal server error' }
      stub_request(:post, create_url)
        .to_return(status: 500, body: error_body.to_json)

      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(error_body)}\n").to_stdout
    end
  end
end
