# rubocop:disable RSpec/FilePath

RSpec.describe InfrastructureTest::Suite do
  let(:suite) { described_class }
  let(:test_run) { Inferno::Entities::TestRun.new(id: SecureRandom.uuid) }
  let(:runner) { Inferno::TestRunner.new(test_session: test_session, test_run: test_run) }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }

  describe 'inline definitions' do
    let(:outer_inline_group) { suite.groups.first }
    let(:inner_inline_group) { outer_inline_group.groups.first }
    let(:inline_test1) { inner_inline_group.tests.first }

    describe 'suite' do
      let(:test_run) { repo_create(:test_run, test_suite_id: suite.id, test_session_id: test_session.id) }

      it 'contains correct metadata' do
        expect(suite.id).to eq('infra_test')
        expect(suite.title).to eq('Infrastructure Test')
        expect(suite.description).to start_with('An internal test suite')
      end

      it 'contains the correct inputs' do
        expect(suite.inputs).to match_array([{ name: :suite_input, type: 'text' }])
      end

      it 'contains the correct outputs' do
        expect(suite.outputs).to match_array([:suite_output])
      end

      it 'contains the correct groups' do
        expect(suite.groups.length).to eq(2)
        expect(suite.groups.first).to eq(outer_inline_group)
      end

      it 'contains its own fhir client' do
        expect(suite.fhir_client_definitions.keys).to eq([:suite])
      end

      it 'passes' do
        results = runner.run(suite)

        expect(results.length).to eq(10)

        non_passing_results = results.reject { |result| result.result == 'pass' }

        expect(non_passing_results).to be_empty, non_passing_results.map { |r|
          "#{r.runnable.title}: #{r.result_message}"
        }.join("\n")
      end
    end

    describe 'outer inline group' do
      let(:test_run) do
        repo_create(
          :test_run,
          runnable: { test_group_id: outer_inline_group.id },
          test_session: test_session
        )
      end

      it 'contains the correct metadata' do
        expect(outer_inline_group.title).to eq('Outer inline group')
        expect(outer_inline_group.id).to eq("#{suite.id}-outer_inline_group")
      end

      it "contains its own inputs as well as its parents' inputs" do
        expect(outer_inline_group.inputs).to match_array([{ name: :suite_input, type: 'text' },
                                                          { name: :outer_group_input, type: 'text' }])
      end

      it "contains its own outputs as well as its parents' outputs" do
        expect(outer_inline_group.outputs).to match_array([:suite_output, :outer_group_output])
      end

      it 'contains the correct groups' do
        expect(outer_inline_group.groups).to match_array([inner_inline_group])
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expect(outer_inline_group.fhir_client_definitions.keys).to eq([:suite, :outer_inline_group])
      end

      it 'passes' do
        results = runner.run(outer_inline_group)

        expect(results.length).to eq(inner_inline_group.tests.length + 2)

        non_passing_results = results.reject { |result| result.result == 'pass' }

        expect(non_passing_results).to be_empty, non_passing_results.map { |r|
          "#{r.runnable.title}: #{r.result_message}"
        }.join("\n")
      end
    end

    describe 'inner inline group' do
      let(:test_run) do
        repo_create(
          :test_run,
          runnable: { test_group_id: inner_inline_group.id },
          test_session: test_session
        )
      end

      it 'contains the correct metadata' do
        expect(inner_inline_group.title).to eq('Inner inline group')
        expect(inner_inline_group.id).to eq("#{suite.id}-outer_inline_group-inner_inline_group")
      end

      it "contains its own inputs as well as its parents' inputs" do
        expect(inner_inline_group.inputs).to match_array([
                                                           { name: :suite_input, type: 'text' },
                                                           { name: :outer_group_input, type: 'text' },
                                                           { name: :inner_group_input, type: 'text' }
                                                         ])
      end

      it "contains its own outputs as well as its parents' outputs" do
        expect(inner_inline_group.outputs).to match_array([:suite_output, :outer_group_output, :inner_group_output])
      end

      it 'contains the correct groups' do
        expect(inner_inline_group.groups).to match_array([])
      end

      it 'contains the correct tests' do
        expect(inner_inline_group.tests.length).to eq(4)
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expected_clients = [:suite, :outer_inline_group, :inner_inline_group]
        expect(inner_inline_group.fhir_client_definitions.keys).to eq(expected_clients)
      end

      it 'passes' do
        results = runner.run(inner_inline_group)

        expect(results.length).to eq(inner_inline_group.tests.length + 1)

        non_passing_results = results.reject { |result| result.result == 'pass' }

        expect(non_passing_results).to be_empty, non_passing_results.map { |r|
          "#{r.runnable.title}: #{r.result_message}"
        }.join("\n")
      end
    end

    describe 'inline test 1' do
      let(:test_run) do
        repo_create(
          :test_run,
          runnable: { test_id: inline_test1.id },
          test_session: test_session
        )
      end

      it 'contains the correct metadata' do
        expect(inline_test1.title).to eq('Inline test 1')
        expect(inline_test1.id).to eq("#{suite.id}-outer_inline_group-inner_inline_group-inline_test_1")
      end

      it "contains its own inputs as well as its parents' inputs" do
        expected_inputs = [
          { name: :suite_input, type: 'text' },
          { name: :outer_group_input, type: 'text' },
          { name: :inner_group_input, type: 'text' },
          { name: :test_input, type: 'text' }
        ]
        expect(inline_test1.inputs).to match_array(expected_inputs)
      end

      it "contains its own outputs as well as its parents' outputs" do
        expected_outputs = [:suite_output, :outer_group_output, :inner_group_output, :test_output]
        expect(inline_test1.outputs).to match_array(expected_outputs)
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expected_clients = [:suite, :outer_inline_group, :inner_inline_group, :inline_test1]
        expect(inline_test1.fhir_client_definitions.keys).to eq(expected_clients)
      end

      it 'passes' do
        results = runner.run(inline_test1)

        expect(results.length).to eq(1)

        non_passing_results = results.reject { |result| result.result == 'pass' }

        expect(non_passing_results).to be_empty, non_passing_results.map { |r|
          "#{r.runnable.title}: #{r.result_message}"
        }.join("\n")
      end
    end
  end

  describe 'external definitions' do
    let(:external_outer_group_base) { InfrastructureTest::ExternalOuterGroup }
    let(:external_outer_group) { suite.groups.last }
    let(:external_inner_group_base) { InfrastructureTest::ExternalInnerGroup }
    let(:external_inner_group) { external_outer_group.groups.last }
    let(:external_test) { external_inner_group.tests.first }

    describe 'suite' do
      it 'contains an externally defined group' do
        expect(external_outer_group.ancestors).to include(external_outer_group_base)
      end
    end

    describe 'outer external group' do
      let(:test_run) do
        repo_create(
          :test_run,
          runnable: { test_group_id: external_outer_group.id },
          test_session: test_session
        )
      end

      it 'contains a nested id' do
        expect(external_outer_group.id).to eq("#{suite.id}-#{external_outer_group_base.id}")
      end

      it "contains its own inputs as well as its parents' inputs" do
        expect(external_outer_group.inputs).to match_array([{ name: :suite_input, type: 'text' },
                                                            { name: :external_outer_group_input, type: 'text' }])
      end

      it "contains its own outputs as well as its parents' outputs" do
        expect(external_outer_group.outputs).to match_array([:suite_output, :external_outer_group_output])
      end

      it 'contains an externally defined inner group' do
        expect(external_outer_group.groups.length).to eq(1)
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expect(external_outer_group.fhir_client_definitions.keys).to match_array([:suite, :external_outer_group])
      end

      it 'passes' do
        results = runner.run(external_outer_group)

        expect(results.length).to eq(3)

        non_passing_results = results.reject { |result| result.result == 'pass' }

        expect(non_passing_results).to be_empty, non_passing_results.map { |r|
          "#{r.runnable.title}: #{r.result_message}"
        }.join("\n")
      end
    end

    describe 'inner external group' do
      let(:test_run) do
        repo_create(
          :test_run,
          runnable: { test_group_id: external_inner_group.id },
          test_session: test_session
        )
      end

      it 'contains a nested id' do
        expected_id = "#{suite.id}-#{external_outer_group_base.id}-external_inner_group"
        expect(external_inner_group.id).to eq(expected_id)
      end

      it "contains its own inputs as well as its parents' inputs" do
        expected_inputs = [{ name: :suite_input, type: 'text' }, { name: :external_outer_group_input, type: 'text' },
                           { name: :external_inner_group_input, type: 'text' }]
        expect(external_inner_group.inputs).to match_array(expected_inputs)
      end

      it "contains its own outputs as well as its parents' outputs" do
        expected_outputs = [:suite_output, :external_outer_group_output, :external_inner_group_output]
        expect(external_inner_group.outputs).to match_array(expected_outputs)
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expected_clients = [:suite, :external_outer_group, :external_inner_group]
        expect(external_inner_group.fhir_client_definitions.keys).to match_array(expected_clients)
      end

      it 'contains an externally defined test' do
        expect(external_inner_group.tests.length).to eq(1)
      end

      it 'passes' do
        results = runner.run(external_inner_group)

        expect(results.length).to eq(2)

        non_passing_results = results.reject { |result| result.result == 'pass' }

        expect(non_passing_results).to be_empty, non_passing_results.map { |r|
          "#{r.runnable.title}: #{r.result_message}"
        }.join("\n")
      end
    end

    describe 'external test' do
      let(:test_run) do
        repo_create(
          :test_run,
          runnable: { test_id: external_test.id },
          test_session: test_session
        )
      end

      it 'contains a nested id' do
        expected_id = "#{suite.id}-#{external_outer_group_base.id}-#{external_inner_group_base.id}-external_test1"
        expect(external_test.id).to eq(expected_id)
      end

      it "contains its own inputs as well as its parents' inputs" do
        expected_inputs = [
          { name: :suite_input, type: 'text' },
          { name: :external_outer_group_input, type: 'text' },
          { name: :external_inner_group_input, type: 'text' },
          { name: :external_test1_input, type: 'text' }
        ]
        expect(external_test.inputs).to match_array(expected_inputs)
      end

      it "contains its own outputs as well as its parents' outputs" do
        expected_outputs = [
          :suite_output,
          :external_outer_group_output,
          :external_inner_group_output,
          :external_test1_output
        ]
        expect(external_test.outputs).to match_array(expected_outputs)
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expected_clients = [:suite, :external_outer_group, :external_inner_group, :external_test1]
        expect(external_test.fhir_client_definitions.keys).to match_array(expected_clients)
      end

      it 'passes' do
        results = runner.run(external_test)

        expect(results.length).to eq(1)

        non_passing_results = results.reject { |result| result.result == 'pass' }

        expect(non_passing_results).to be_empty, non_passing_results.map { |r|
          "#{r.runnable.title}: #{r.result_message}"
        }.join("\n")
      end
    end
  end
end

# rubocop:enable RSpec/FilePath
