require_relative '../../../../lib/inferno/apps/cli/session/cancel_run'

RSpec.describe Inferno::CLI::Session::CancelRun do
  let(:session_id) { 'test-session-id' }
  let(:run_id) { 'test-run-id' }
  let(:inferno_host) { 'https://inferno.healthit.gov/suites' }
  let(:options) { { inferno_base_url: inferno_host } }
  let(:last_test_run_url) { "#{inferno_host}/api/test_sessions/#{session_id}/last_test_run" }
  let(:delete_run_url) { "#{inferno_host}/api/test_runs/#{run_id}" }

  def stub_last_test_run(status:)
    stub_request(:get, last_test_run_url)
      .to_return(status: 200, body: { id: run_id, status: status }.to_json)
  end

  def stub_delete_run(status: 204)
    stub_request(:delete, delete_run_url)
      .to_return(status: status, body: '')
  end

  describe '#run' do
    described_class::CANCELLABLE_STATUSES.each do |run_status|
      it "outputs confirmation and exits 0 when run status is '#{run_status}'" do
        stub_last_test_run(status: run_status)
        delete_request = stub_delete_run

        expected_output = { run_id: run_id, cancelled: true }
        expect do
          expect { described_class.new(session_id, options).run }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
        end.to output("#{JSON.pretty_generate(expected_output)}\n").to_stdout

        expect(delete_request).to have_been_made.once
      end
    end

    %w[done cancelled created].each do |run_status|
      it "exits 3 with an error and does not delete when run status is '#{run_status}'" do
        stub_last_test_run(status: run_status)

        expected_error = { errors: "Run '#{run_id}' cannot be cancelled: status is '#{run_status}'" }
        expect do
          expect { described_class.new(session_id, options).run }
            .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
        end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout

        expect(a_request(:delete, delete_run_url)).to_not have_been_made
      end
    end

    it 'exits 3 and prints the error body when the delete request fails' do
      stub_last_test_run(status: 'running')
      error_body = { errors: 'Internal server error' }
      stub_request(:delete, delete_run_url)
        .to_return(status: 500, body: error_body.to_json)

      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(error_body)}\n").to_stdout
    end

    it 'exits 3 and prints a not-found error when the session is not found' do
      stub_request(:get, last_test_run_url)
        .to_return(status: 404, body: 'Not Found')

      expected_error = { errors: "Session '#{session_id}' not found on Inferno host at '#{inferno_host}/'" }
      expect do
        expect { described_class.new(session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output("#{JSON.pretty_generate(expected_error)}\n").to_stdout
    end
  end
end
