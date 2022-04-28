RSpec.describe Inferno::TestRunner do
  let(:runner) { described_class.new(test_session: test_session, test_run: test_run) }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'demo') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def error_results_message(error_results)
    error_results.map do |r|
      "#{r.runnable.title}: #{r.result_message}"
    end.join("\n")
  end

  describe 'when running demo group' do
    let(:test_run) do
      repo_create(:test_run, runnable: { test_group_id: group.id }, test_session_id: test_session.id)
    end
    let(:base_url) { 'http://hapi.fhir.org/baseR4' }
    let(:patient_id) { 1215072 }
    let(:group) { Inferno::Repositories::TestGroups.new.find('demo-simple_group') }
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
          value: value,
          type: 'text'
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
      test_count = group.test_count

      results = runner.start

      # Plus two for the group results
      expect(results.length).to eq(test_count + 2)
    end

    it 'only contains no "error" results apart from the "locked input" and "error test"' do
      results = runner.start
      error_results =
        results
          .reject { |result| result.test&.title == 'locked input' }
          .reject { |result| result.test&.title == 'error test' }
          .reject { |result| result.runnable < Inferno::Entities::TestGroup }
          .select { |result| result.result == 'error' }

      expect(error_results).to be_empty, error_results_message(error_results)
    end

    it 'includes output types in the results' do
      results = runner.start

      result_outputs =
        results
          .map(&:output_json)
          .compact
          .map { |output_json| JSON.parse(output_json) }
          .select(&:present?)
          .flatten

      result_outputs.each do |output|
        expect(output['type']).to be_present
      end
    end
  end

  describe 'when running wait group' do
    let(:test_run) do
      repo_create(:test_run, runnable: { test_group_id: group.id }, test_session_id: test_session.id)
    end
    let(:group) { Inferno::Repositories::TestGroups.new.find('demo-wait_group') }

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

  describe 'when a request can not be loaded' do
    let(:test_run) do
      repo_create(:test_run, runnable: { test_group_id: group.id }, test_session_id: test_session.id)
    end
    let(:group) { DemoIG_STU1::DemoGroup }

    it 'generates a skip result' do
      test = DemoIG_STU1::DemoGroup.tests.find { |group_test| group_test.title == 'use named fhir request' }

      runner.run(test)

      results = results_repo.current_results_for_test_session(test_session.id)

      expect(results.length).to eq(1)
      expect(results.first.result).to eq('skip')
    end
  end

  describe 'when suite options are used' do
    let(:test_run) do
      repo_create(:test_run, runnable: { test_suite_id: suite.id }, test_session_id: test_session.id)
    end

    let(:suite) { OptionsSuite::Suite }

    it 'only runs groups which should be included based on options' do
      test_session.suite_options = { ig_version: '1' }

      runner.run(suite)

      results = results_repo.current_results_for_test_session(test_session.id)

      expect(results.length).to eq(5)

      runnable_ids = results.map(&:runnable).map(&:id)

      expect(runnable_ids).to all(exclude('v2'))
    end
  end
end
