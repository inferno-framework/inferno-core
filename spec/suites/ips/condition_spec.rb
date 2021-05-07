RSpec.describe IPS::Condition do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('ips') }
  let(:group) { suite.groups[1].groups[21] }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'ips') }
  let(:url) { 'http://example.com/fhir' }
  let(:error_outcome) { FHIR::OperationOutcome.new(issue: [{ severity: 'error' }]) }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable, inputs)
    Inferno::Repositories::TestRuns.new.results_for_test_run(test_run.id)
  end

  describe 'read test' do
    let(:test) { group.tests.first }
    let(:condition_id) { 'abc123' }

    it 'passes if a Condition was received' do
      resource = FHIR::Condition.new(id: condition_id)
      stub_request(:get, "#{url}/Condition/#{condition_id}")
        .to_return(status: 200, body: resource.to_json)

      result = run(test, url: url, condition_id: condition_id).first

      expect(result.result).to eq('pass')
    end

    it 'fails if a 200 is not received' do
      resource = FHIR::Condition.new(id: condition_id)
      stub_request(:get, "#{url}/Condition/#{condition_id}")
        .to_return(status: 201, body: resource.to_json)

      result = run(test, url: url, condition_id: condition_id).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/200/)
    end

    it 'fails if a Condition is not received' do
      resource = FHIR::Patient.new(id: condition_id)
      stub_request(:get, "#{url}/Condition/#{condition_id}")
        .to_return(status: 200, body: resource.to_json)

      result = run(test, url: url, condition_id: condition_id).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Condition/)
    end

    it 'fails if the id received does not match the one requested' do
      resource = FHIR::Condition.new(id: '456')
      stub_request(:get, "#{url}/Condition/#{condition_id}")
        .to_return(status: 200, body: resource.to_json)

      result = run(test, url: url, condition_id: condition_id).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/resource with id/)
    end
  end

  describe 'validation test' do
    let(:test) { group.tests.last }

    it 'passes if the resource is valid' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      resource = FHIR::Condition.new
      repo_create(
        :request,
        name: :condition,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('pass')
    end

    it 'fails if the resource is not valid' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: error_outcome.to_json)

      resource = FHIR::Condition.new
      repo_create(
        :request,
        name: :condition,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('fail')
    end
  end
end
