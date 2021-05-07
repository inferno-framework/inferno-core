RSpec.describe Covid19VCI::FileDownload do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('c19-vci') }
  let(:runner) { Inferno::TestRunner.new(test_session: test_session, test_run: test_run) }
  let(:test_session) do
    Inferno::Repositories::TestSessions.new.create(test_suite_id: suite.id)
  end
  let(:request_repo) { Inferno::Repositories::Requests.new }
  let(:group) { suite.groups.first }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable, inputs)
    Inferno::Repositories::TestRuns.new.results_for_test_run(test_run.id)
  end

  describe 'vci-file-01' do
    let(:test) { group.tests.first }
    let(:url) { 'http://example.com/hc' }

    it 'passes if valid json is downloaded' do
      stubbed_request =
        stub_request(:get, url)
          .to_return(status: 200, body: { abc: 'def' }.to_json)

      result = run(test, { file_download_url: url }).first

      expect(stubbed_request).to have_been_made.once
      expect(result.result).to eq('pass')
    end

    it 'fails if a non-200 status code is received' do
      stubbed_request =
        stub_request(:get, url)
          .to_return(status: 500, body: { abc: 'def' }.to_json)

      result = run(test, { file_download_url: url }).first

      expect(stubbed_request).to have_been_made.once
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/200/)
    end

    it 'fails if a non-JSON payload is received' do
      stubbed_request =
        stub_request(:get, url)
          .to_return(status: 200, body: 'def')

      result = run(test, { file_download_url: url }).first

      expect(stubbed_request).to have_been_made.once
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/JSON/)
    end
  end

  describe 'vci-file-02' do
    let(:test) { group.tests[1] }

    it 'passes if the response has the correct Content-Type header' do
      request_repo.create(
        status: 200,
        response_headers: [{ name: 'content-type', value: 'application/smart-health-card' }],
        name: :vci_file_download,
        test_session_id: test_session.id
      )

      result = run(test).first

      expect(result.result).to eq('pass')
    end

    it 'errors if the vci_file_download request has not been made' do
      result = run(test).first

      expect(result.result).to eq('error')
      expect(result.result_message).to match(/vci_file_download/)
    end

    it 'skips if a non-200 response was received' do
      request_repo.create(
        status: 500,
        name: :vci_file_download,
        test_session_id: test_session.id
      )
      result = run(test).first

      expect(result.result).to eq('skip')
    end

    it 'fails if the response has an incorrect Content-Type header' do
      request_repo.create(
        status: 200,
        response_headers: [{ name: 'content-type', value: 'application/json' }],
        name: :vci_file_download,
        test_session_id: test_session.id
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Content-Type/)
    end

    it 'fails if the response has no Content-Type header' do
      request_repo.create(
        status: 200,
        name: :vci_file_download,
        test_session_id: test_session.id
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/did not include/)
    end
  end

  describe 'vci-file-03' do
    let(:test) { group.tests[2] }

    it 'passes if the download url ends in .smart-health-card' do
      request_repo.create(
        status: 200,
        url: 'http://example.com/hc.smart-health-card',
        name: :vci_file_download,
        test_session_id: test_session.id
      )

      result = run(test).first

      expect(result.result).to eq('pass')
    end

    it 'errors if the vci_file_download request has not been made' do
      result = run(test).first

      expect(result.result).to eq('error')
      expect(result.result_message).to match(/vci_file_download/)
    end

    it 'skips if a non-200 response was received' do
      request_repo.create(
        status: 500,
        name: :vci_file_download,
        test_session_id: test_session.id
      )
      result = run(test).first

      expect(result.result).to eq('skip')
    end

    context 'with a url that does not end in .smart-health-card' do
      let(:url) { 'http://example.com/hc' }

      it 'passes if the response contains a Content-Disposition header with a .smart-health-card extension' do
        request_repo.create(
          status: 200,
          url: url,
          response_headers: [{ name: 'content-disposition', value: 'attachment; filename="hc.smart-health-card"' }],
          name: :vci_file_download,
          test_session_id: test_session.id
        )

        result = run(test).first

        expect(result.result).to eq('pass')
      end

      it 'fails if no Content-Disposition header is received' do
        request_repo.create(
          status: 200,
          url: url,
          name: :vci_file_download,
          test_session_id: test_session.id
        )
        result = run(test).first

        expect(result.result).to eq('fail')
      end

      it 'fails if Content-Disposition header does not indicate the file should be downloaded' do
        request_repo.create(
          status: 200,
          url: url,
          response_headers: [{ name: 'content-disposition', value: 'inline' }],
          name: :vci_file_download,
          test_session_id: test_session.id
        )

        result = run(test).first

        expect(result.result).to eq('fail')
        expect(result.result_message).to match(/should be downloaded/)
      end

      it 'fails if Content-Disposition header does not indicate a .smart-health-card extension' do
        request_repo.create(
          status: 200,
          url: url,
          response_headers: [{ name: 'content-disposition', value: 'attachment; filename="hc.health-card"' }],
          name: :vci_file_download,
          test_session_id: test_session.id
        )
        result = run(test).first

        expect(result.result).to eq('fail')
        expect(result.result_message).to match(/extension/)
      end
    end
  end

  describe 'vci-file-04' do
    let(:test) { group.tests[3] }

    it 'passes if the response contains an array of VC strings' do
      request_repo.create(
        status: 200,
        response_body: { 'verifiableCredential' => ['abc'] }.to_json,
        name: :vci_file_download,
        test_session_id: test_session.id
      )

      result = run(test).first

      expect(result.result).to eq('pass')
    end

    it 'errors if the vci_file_download request has not been made' do
      result = run(test).first

      expect(result.result).to eq('error')
      expect(result.result_message).to match(/vci_file_download/)
    end

    it 'skips if a non-200 response was received' do
      request_repo.create(
        status: 500,
        name: :vci_file_download,
        test_session_id: test_session.id
      )
      result = run(test).first

      expect(result.result).to eq('skip')
    end

    it "fails if the body does not contain a 'verifiableCredential' field" do
      request_repo.create(
        status: 200,
        response_body: {}.to_json,
        name: :vci_file_download,
        test_session_id: test_session.id
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/does not contain/)
    end

    it "fails if the 'verifiableCredential' field does not contain an array" do
      request_repo.create(
        status: 200,
        response_body: { 'verifiableCredential' => 'abc' }.to_json,
        name: :vci_file_download,
        test_session_id: test_session.id
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/must contain an Array/)
    end

    it "fails if the 'verifiableCredential' field contains an empty array" do
      request_repo.create(
        status: 200,
        response_body: { 'verifiableCredential' => [] }.to_json,
        name: :vci_file_download,
        test_session_id: test_session.id
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/at least one/)
    end
  end
end
