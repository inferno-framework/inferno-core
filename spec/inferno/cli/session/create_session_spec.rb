require_relative '../../../../lib/inferno/apps/cli/session/create_session'

RSpec.describe Inferno::CLI::Session::CreateSession do
  let(:suite_id) { 'us_core_v610' }
  let(:suite_title) { 'US Core v6.1.0' }
  let(:suite_short_title) { 'US Core 6' }
  let(:inferno_host) { 'https://inferno.healthit.gov/suites' }
  let(:session_response) { { id: 'new-session-id', test_suite_id: suite_id } }
  let(:create_url) { "#{inferno_host}/api/test_sessions" }
  let(:suites_url) { "#{inferno_host}/api/test_suites" }
  let(:options) { { inferno_base_url: inferno_host } }
  let(:suite_list) do
    [{ id: suite_id, title: suite_title, short_title: suite_short_title,
       presets: [{ id: 'my-preset', title: 'My Preset' }] }].to_json
  end

  before do
    stub_request(:get, suites_url).to_return(status: 200, body: suite_list)
  end

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
        expect { described_class.new(suite_id, options.merge(preset: 'my-preset')).run }
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
      stub_request(:get, suites_url).to_return(
        status: 200,
        body: [{ id: suite_id, title: suite_title, short_title: suite_short_title,
                 presets: [{ id: 'my-preset', title: 'My Preset' }],
                 suite_options: [
                   { id: 'us_core_version', title: 'US Core Version' },
                   { id: 'smart_app_launch_version', title: 'SMART App Launch Version' }
                 ] }].to_json
      )
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

      expected_error = { errors: "Running Inferno host not found at '#{inferno_host}/'" }
      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints a not-found error when the server returns a 404 with a non-JSON body' do
      stub_request(:post, create_url)
        .to_return(status: 404, body: '<html><body>404 Not Found</body></html>')

      expected_error = { errors: "Running Inferno host not found at '#{inferno_host}/'" }
      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints a connection error when Inferno is not reachable' do
      stub_request(:post, create_url)
        .to_raise(Faraday::ConnectionFailed.new('Connection refused'))

      expected_error = { errors: "Could not connect to Inferno at '#{inferno_host}/': Connection refused" }
      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end

    it 'exits 3 and prints a connection error when the request times out' do
      stub_request(:post, create_url)
        .to_raise(Faraday::TimeoutError.new('timeout'))

      expected_error = { errors: "Could not connect to Inferno at '#{inferno_host}/': timeout" }
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

  describe '#resolve_preset_identifier' do
    let(:preset_id) { 'my-preset' }
    let(:preset_title) { 'My Preset' }
    let(:suite_list) do
      [{ id: suite_id, title: suite_title, short_title: suite_short_title,
         presets: [{ id: preset_id, title: preset_title }] }].to_json
    end

    it 'leaves preset_id unchanged when it matches an existing preset id' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id, preset_id: })
        .to_return(status: 200, body: session_response.to_json)

      described_class.new(suite_id, options.merge(preset: preset_id)).create_session

      expect(create_request).to have_been_made.once
    end

    it 'resolves preset_id from a matching title' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id, preset_id: })
        .to_return(status: 200, body: session_response.to_json)

      described_class.new(suite_id, options.merge(preset: preset_title)).create_session

      expect(create_request).to have_been_made.once
    end

    it 'exits 3 with an error when the preset identifier does not match any preset' do
      expect do
        expect { described_class.new(suite_id, options.merge(preset: 'unknown-preset')).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/Preset 'unknown-preset' not found/).to_stdout
    end

    it 'skips resolution when no preset is specified' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id })
        .to_return(status: 200, body: session_response.to_json)

      described_class.new(suite_id, options).create_session

      expect(create_request).to have_been_made.once
    end
  end

  describe '#suite_options_list' do
    let(:suite_options_suite_list) do
      [{ id: suite_id, title: suite_title, short_title: suite_short_title,
         presets: [],
         suite_options: [
           { 'id' => 'ig_version', 'title' => 'IG Version',
             'list_options' => [{ 'value' => '1', 'label' => 'v1' }, { 'value' => '2', 'label' => 'v2' }] },
           { 'id' => 'another_option', 'title' => 'Another option',
             'list_options' => [{ 'value' => 'a', 'label' => 'option a' }, { 'value' => 'b', 'label' => 'option b' }] }
         ] }].to_json
    end

    before do
      stub_request(:get, suites_url).to_return(status: 200, body: suite_options_suite_list)
    end

    it 'resolves a suite option key provided as a display title to its internal id' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id, suite_options: [{ id: 'ig_version', value: '1' }] })
        .to_return(status: 200, body: session_response.to_json)

      described_class.new(suite_id, options.merge(suite_options: { 'IG Version' => '1' })).create_session

      expect(create_request).to have_been_made.once
    end

    it 'resolves a suite option value provided as a display label to its internal value' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id, suite_options: [{ id: 'ig_version', value: '2' }] })
        .to_return(status: 200, body: session_response.to_json)

      described_class.new(suite_id, options.merge(suite_options: { 'ig_version' => 'v2' })).create_session

      expect(create_request).to have_been_made.once
    end

    it 'resolves both key by title and value by label in the same call' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id, suite_options: [{ id: 'another_option', value: 'b' }] })
        .to_return(status: 200, body: session_response.to_json)

      described_class.new(suite_id, options.merge(suite_options: { 'Another option' => 'option b' })).create_session

      expect(create_request).to have_been_made.once
    end

    it 'exits 3 when the suite option key does not match any id or title' do
      expect do
        expect { described_class.new(suite_id, options.merge(suite_options: { 'unknown_opt' => '1' })).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/Unknown suite option 'unknown_opt'/).to_stdout
    end

    it 'exits 3 when the suite option value does not match any value or label' do
      expect do
        expect { described_class.new(suite_id, options.merge(suite_options: { 'ig_version' => 'v99' })).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/Invalid value 'v99' for suite option 'ig_version'/).to_stdout
    end
  end

  describe '#resolve_suite_identifier' do
    it 'leaves suite_id unchanged when it matches an existing suite id' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id })
        .to_return(status: 200, body: session_response.to_json)

      described_class.new(suite_id, options).create_session

      expect(create_request).to have_been_made.once
    end

    it 'resolves suite_id from a matching title' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id })
        .to_return(status: 200, body: session_response.to_json)

      described_class.new(suite_title, options).create_session

      expect(create_request).to have_been_made.once
    end

    it 'resolves suite_id from a matching short_title' do
      create_request = stub_request(:post, create_url)
        .with(body: { test_suite_id: suite_id })
        .to_return(status: 200, body: session_response.to_json)

      described_class.new(suite_short_title, options).create_session

      expect(create_request).to have_been_made.once
    end

    it 'exits 3 with an error when the suite identifier does not match any suite' do
      expect do
        expect { described_class.new('unknown_suite', options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/Suite 'unknown_suite' not found/).to_stdout
    end

    it 'exits 3 when the test_suites list cannot be fetched' do
      stub_request(:get, suites_url).to_return(status: 500, body: 'error')

      expect do
        expect { described_class.new(suite_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/Could not fetch test suites list/).to_stdout
    end
  end
end
