RSpec.shared_context('when testing a runnable') do
  let(:suite) { Inferno::Repositories::TestSuites.new.find(suite_id) }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:validation_url) { "#{ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')}/validate" }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }

  before do
    if !(described_class.singleton_class < Inferno::DSL::Runnable) ||
       described_class.parent.nil?
      allow(described_class).to receive(:suite).and_return(suite)
    end
  rescue NameError
    raise StandardError, "No suite id defined. Add `let(:suite_id) { 'your_suite_id' }` to the spec"
  end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name)
      )
    end

    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  # depth-first search looking for a runnable with a runtime id
  # (prefixed with the ancestor suite / group ids) that ends
  # with the provided suffix. It can be the test's id if unique, or
  # can include some ancestor context if needed to identify the
  # correct test. The first matching test found will be returned.
  def find_test(runnable, id_suffix)
    return runnable if runnable.id.ends_with?(id_suffix)

    runnable.children.each do |entity|
      found = find_test(entity, id_suffix)
      return found unless found.nil?
    end

    nil
  end
end
