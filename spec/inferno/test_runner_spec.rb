# NOTE: These are basic placeholder specs to make sure we don't break this as we
#   refactor.
RSpec.describe Inferno::TestRunner do
  let(:runner) { described_class.new(test_session: test_session, test_run: test_run) }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'demo') }
  let(:test_run) do
    repo_create(:test_run, runnable: { test_group_id: group.id }, test_session_id: test_session.id)
  end
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def error_results_message(error_results)
    error_results.map do |r|
      "#{r.runnable.title}: #{r.result_message}"
    end.join("\n")
  end

  describe 'when running demo group' do
    let(:base_url) { 'http://hapi.fhir.org/baseR4' }
    let(:patient_id) { 1215072 }
    let(:group) { Inferno::Repositories::TestSuites.new.find('demo').groups.first.groups.first }
    let(:patient) { FHIR::Patient.new(id: patient_id) }
    let(:observation_bundle) do
      FHIR::Bundle.new(
        entry: [
          {
            resource: FHIR::Observation.new(id: 123)
          }
        ]
      )
    end

    before do
      stub_request(:get, "#{base_url}/Patient/#{patient_id}")
        .to_return(status: 200, body: patient.to_json)
      stub_request(:get, "#{base_url}/Observation")
        .with(query: { 'patient' => patient_id })
        .to_return(status: 200, body: observation_bundle.to_json)
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)
      stub_request(:get, 'http://example.com')
        .to_return(status: 200)
      { url: base_url, patient_id: patient_id }.each do |name, value|
        session_data_repo.save(
          test_session_id: test_session.id,
          name: name,
          value: value
        )
        stub_request(:get, base_url)
          .to_return(status: 200, body: '', headers: {})
      end
    end

    it 'runs' do
      expect do
        runner.start
      end.to_not raise_error
    end

    it 'creates results' do
      test_count = group.tests.length

      results = runner.start

      expect(results.length).to eq(test_count + 2)
    end

    it 'only contains no "error" results apart from the "error test"' do
      results = runner.start
      error_results =
        results
          .reject { |result| result.test&.title == 'error test' }
          .reject { |result| result.runnable < Inferno::Entities::TestGroup }
          .select { |result| result.result == 'error' }

      expect(error_results).to be_empty, error_results_message(error_results)
    end
  end

  describe 'when running wait group' do
    let(:group) do
      Inferno::Repositories::TestSuites.new.find('demo').groups.find do |group|
        group.id == 'demo-wait_group'
      end
    end

    it 'gives a wait result' do
      result = runner.run(group)

      expect(result.result).to eq('wait')
    end

    it 'does not run the last test' do
      runner.run(group)

      results = results_repo.current_results_for_test_session(test_session.id)

      expect(results.length).to eq(3)
    end
  end
end
