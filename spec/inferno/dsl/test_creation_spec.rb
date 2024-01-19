# rubocop:disable RSpec/FilePath

RSpec.describe InfrastructureTest::Suite do
  let(:suite) { described_class }
  let(:test_run) { Inferno::Entities::TestRun.new(id: SecureRandom.uuid) }
  let(:runner) { Inferno::TestRunner.new(test_session:, test_run:) }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }
  let(:results_repo) { Inferno::Repositories::Results.new }

  describe 'inline definitions' do
    let(:outer_inline_group) { suite.groups.first }
    let(:inner_inline_group) { outer_inline_group.groups.first }
    let(:inline_test1) { inner_inline_group.tests.first }

    describe 'suite' do
      let(:test_run) { repo_create(:test_run, test_suite_id: suite.id, test_session_id: test_session.id) }

      it 'contains correct metadata' do
        expect(suite.id).to eq('infra_test')
        expect(suite.title).to eq('Infrastructure Test Suite')
        expect(suite.short_title).to eq('Infrastructure')
        expect(suite.description).to start_with('An internal test suite to verify that inferno infrastructure works')
        expect(suite.short_description).to start_with('Internal test suite')
        expect(suite.input_instructions).to include('Instructions for inputs')
      end

      it 'contains the correct inputs' do
        expect(suite.inputs).to match_array([:suite_input])
      end

      it 'contains the correct outputs' do
        expect(suite.outputs).to match_array([:suite_output])
      end

      it 'contains the correct groups' do
        expect(suite.groups.length).to eq(6)
        expect(suite.groups.first).to eq(outer_inline_group)
      end

      it 'contains groups with correct short_ids' do
        expected_short_ids = Array(1..suite.groups.length).map(&:to_s)
        found_short_ids = suite.groups.map(&:short_id)

        expect(found_short_ids).to eq(expected_short_ids)
      end

      it 'contains its own fhir client' do
        expect(suite.fhir_client_definitions.keys).to eq([:suite])
      end

      it 'contains failing optional tests' do
        runner.run(suite)
        results = results_repo.current_results_for_test_session(test_session.id)

        optional_results = results.select(&:optional?)
        failing_optional_results = optional_results.select { |result| result.result == 'fail' }
        expect(failing_optional_results).to_not be_empty
      end

      it 'passes' do
        runner.run(suite)

        results = results_repo.current_results_for_test_session(test_session.id)

        expect(results.length).to eq(17)

        required_results = results.reject(&:optional?)
        non_passing_results = required_results.reject { |result| result.result == 'pass' }
        bad_results = non_passing_results.reject do |result|
          result.test_group.id == 'infra_test-empty_group' && result.result == 'omit'
        end

        expect(bad_results).to be_empty, bad_results.map { |r|
          "#{r.runnable.title}: #{r.result_message}"
        }.join("\n")
      end
    end

    describe 'outer inline group' do
      let(:test_run) do
        repo_create(
          :test_run,
          runnable: { test_group_id: outer_inline_group.id },
          test_session:
        )
      end

      it 'contains the correct metadata' do
        expect(outer_inline_group.title).to eq('Outer inline group title')
        expect(outer_inline_group.short_title).to eq('Outer inline group short title')
        expect(outer_inline_group.description).to eq('Outer inline group for testing description')
        expect(outer_inline_group.short_description).to eq('Outer inline group short description')
        expect(outer_inline_group.id).to eq("#{suite.id}-outer_inline_group")
        expect(outer_inline_group.short_id).to eq('1')
      end

      it "contains its own inputs as well as its parents' inputs" do
        expect(outer_inline_group.inputs).to match_array([:suite_input, :outer_group_input])
      end

      it "contains its own outputs as well as its parents' outputs" do
        expect(outer_inline_group.outputs).to match_array([:suite_output, :outer_group_output])
      end

      it 'contains the correct groups' do
        expect(outer_inline_group.groups).to match_array([inner_inline_group])
      end

      it 'contains groups with correct short_ids' do
        expected_short_ids = Array(1..outer_inline_group.groups.length).map do |id|
          "#{outer_inline_group.short_id}." + id.to_s
        end

        found_short_ids = outer_inline_group.groups.map(&:short_id)
        expect(found_short_ids).to eq(expected_short_ids)
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expect(outer_inline_group.fhir_client_definitions.keys).to eq([:suite, :outer_inline_group])
      end

      it 'passes' do
        runner.run(outer_inline_group)

        results = results_repo.current_results_for_test_session(test_session.id)

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
          test_session:
        )
      end

      it 'contains the correct metadata' do
        expect(inner_inline_group.title).to eq('Inner inline group')
        expect(inner_inline_group.short_title).to eq('Inner inline group short title')
        expect(inner_inline_group.id).to eq("#{suite.id}-outer_inline_group-inner_inline_group")
        expect(inner_inline_group.short_id).to eq("#{outer_inline_group.short_id}.1")
      end

      it "contains its own inputs as well as its parents' inputs" do
        expect(inner_inline_group.inputs).to match_array([:suite_input, :outer_group_input, :inner_group_input])
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

      it 'contains tests with correct short_ids' do
        expected_short_ids = Array(1..inner_inline_group.tests.length).map do |id|
          "#{inner_inline_group.short_id}." + id.to_s.rjust(2, '0')
        end

        found_short_ids = inner_inline_group.tests.map(&:short_id)
        expect(found_short_ids).to eq(expected_short_ids)
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expected_clients = [:suite, :outer_inline_group, :inner_inline_group]
        expect(inner_inline_group.fhir_client_definitions.keys).to eq(expected_clients)
      end

      it 'passes' do
        runner.run(inner_inline_group)

        results = results_repo.current_results_for_test_session(test_session.id)

        expect(results.length).to eq(inner_inline_group.tests.length + 2)

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
          test_session:
        )
      end

      it 'contains the correct metadata' do
        expect(inline_test1.title).to eq('Inline test 1')
        expect(inline_test1.short_title).to eq('Inline test 1')
        expect(inline_test1.description).to eq('Inline test 1 full description')
        expect(inline_test1.short_description).to eq('Inline test 1 short description')
        expect(inline_test1.id).to eq("#{suite.id}-outer_inline_group-inner_inline_group-inline_test_1")
        expect(inline_test1.short_id).to eq("#{inner_inline_group.short_id}.01")
      end

      it "contains its own inputs as well as its parents' inputs" do
        expected_inputs = [:suite_input, :outer_group_input, :inner_group_input, :test_input]
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
        result = runner.run(inline_test1)

        expect(result.result).to eq('pass')
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
          test_session:
        )
      end

      it 'contains a nested id' do
        expect(external_outer_group.id).to eq("#{suite.id}-#{external_outer_group_base.id}")
      end

      it "contains its own inputs as well as its parents' inputs" do
        expect(external_outer_group.inputs).to match_array([:suite_input, :external_outer_group_input])
      end

      it "contains its own outputs as well as its parents' outputs" do
        expect(external_outer_group.outputs).to match_array([:suite_output, :external_outer_group_output])
      end

      it 'contains the correct short_id' do
        expect(external_outer_group.short_id).to eq(suite.groups.length.to_s)
      end

      it 'contains groups with correct short_ids' do
        expected_short_ids = Array(1..external_outer_group.groups.length).map do |id|
          "#{external_outer_group.short_id}." + id.to_s
        end

        found_short_ids = external_outer_group.groups.map(&:short_id)
        expect(found_short_ids).to eq(expected_short_ids)
      end

      it 'contains an externally defined inner group' do
        expect(external_outer_group.groups.length).to eq(1)
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expect(external_outer_group.fhir_client_definitions.keys).to match_array([:suite, :external_outer_group])
      end

      it 'passes' do
        runner.run(external_outer_group)

        results = results_repo.current_results_for_test_session(test_session.id)

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
          test_session:
        )
      end

      it 'contains a nested id' do
        expected_id = "#{suite.id}-#{external_outer_group_base.id}-external_inner_group"
        expect(external_inner_group.id).to eq(expected_id)
      end

      it "contains its own inputs as well as its parents' inputs" do
        expected_inputs = [:suite_input, :external_outer_group_input, :external_inner_group_input]
        expect(external_inner_group.inputs).to match_array(expected_inputs)
      end

      it "contains its own outputs as well as its parents' outputs" do
        expected_outputs = [:suite_output, :external_outer_group_output, :external_inner_group_output]
        expect(external_inner_group.outputs).to match_array(expected_outputs)
      end

      it 'contains the correct short_id' do
        expect(external_inner_group.short_id)
          .to eq("#{external_outer_group.short_id}.#{external_outer_group.groups.length}")
      end

      it "contains its own fhir clients as well as its parents' fhir clients" do
        expected_clients = [:suite, :external_outer_group, :external_inner_group]
        expect(external_inner_group.fhir_client_definitions.keys).to match_array(expected_clients)
      end

      it 'contains an externally defined test' do
        expect(external_inner_group.tests.length).to eq(1)
      end

      it 'contains tests with correct short_ids' do
        expected_short_ids = Array(1..external_inner_group.tests.length).map do |id|
          "#{external_inner_group.short_id}." + id.to_s.rjust(2, '0')
        end

        found_short_ids = external_inner_group.tests.map(&:short_id)
        expect(found_short_ids).to eq(expected_short_ids)
      end

      it 'passes' do
        runner.run(external_inner_group)

        results = results_repo.current_results_for_test_session(test_session.id)

        expect(results.length).to eq(3)

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
          test_session:
        )
      end

      it 'contains a nested id' do
        expected_id = "#{suite.id}-#{external_outer_group_base.id}-#{external_inner_group_base.id}-external_test1"
        expect(external_test.id).to eq(expected_id)
      end

      it 'contains the correct short_id' do
        expect(external_test.short_id)
          .to eq("#{external_inner_group.short_id}.#{external_inner_group.tests.length.to_s.rjust(2, '0')}")
      end

      it "contains its own inputs as well as its parents' inputs" do
        expected_inputs = [
          :suite_input,
          :external_outer_group_input,
          :external_inner_group_input,
          :external_test1_input
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
        result = runner.run(external_test)

        expect(result.result).to eq('pass')
      end
    end

    describe 'mixed_optional_group' do
      context 'with the original group' do
        it 'contains two tests' do
          group = Inferno::Repositories::TestGroups.new.find('mixed_optional_group')

          expect(group.tests.length).to eq(2)
        end
      end

      context 'when imported with exclude_optional: true' do
        it 'only contains the required test' do
          group = Inferno::Repositories::TestGroups.new.find('infra_test-mixed_optional_group')

          expect(group.tests.length).to eq(1)
          expect(group.tests.first).to be_required
        end
      end
    end

    describe 'empty_group' do
      let(:empty_group) { InfrastructureTest::EmptyGroup }
      let(:test_run) do
        repo_create(
          :test_run,
          runnable: { test_group_id: empty_group.id },
          test_session:
        )
      end

      it 'contains zero tests' do
        expect(empty_group.tests.length).to eq(0)
      end
    end
  end
end

# rubocop:enable RSpec/FilePath
