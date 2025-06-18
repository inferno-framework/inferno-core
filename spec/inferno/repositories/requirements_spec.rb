RSpec.describe Inferno::Repositories::Requirements do
  subject(:repo) { described_class.new }

  let(:suite) { RequirementsSuite::Suite }
  let(:complete_requirement_set) { suite.requirement_sets.first }
  let(:empty_requirement_set) do
    Inferno::DSL::RequirementSet.new(
      identifier: 'sample-criteria-proposal',
      actor: 'Server'
    )
  end
  let(:not_tested_requirement_set) do
    Inferno::DSL::RequirementSet.new(
      identifier: 'sample-criteria-proposal-4',
      actor: 'Client'
    )
  end
  let(:filtered_requriment_set) do
    Inferno::DSL::RequirementSet.new(
      identifier: 'sample-criteria-proposal',
      actor: 'Client',
      requirements: '1, 3, 4-6'
    )
  end
  let(:referenced_requirement_sets) do
    [
      Inferno::DSL::RequirementSet.new(
        identifier: 'sample-criteria-proposal-2',
        actor: 'Client'
      ),
      Inferno::DSL::RequirementSet.new(
        identifier: 'sample-criteria-proposal-3',
        actor: 'Client',
        requirements: 'Referenced'
      )
    ]
  end

  describe '#insert_from_file' do
    let(:csv) do
      File.realpath(File.join(Dir.pwd, 'spec/fixtures/simple_requirements.csv'))
    end
    let(:req1) do
      Inferno::Entities::Requirement.new(
        {
          id: 'sample-criteria@1',
          requirement: 'requirement',
          requirement_set: 'sample-criteria',
          conformance: 'SHALL',
          actors: ['Client'],
          sub_requirements: ['sample-criteria@2'],
          conditionality: 'false'
        }
      )
    end
    let(:req2) do
      Inferno::Entities::Requirement.new(
        {
          id: 'sample-criteria@2',
          requirement: 'requirement',
          requirement_set: 'sample-criteria',
          conformance: 'SHALL',
          actors: ['Client', 'Server'],
          sub_requirements: [],
          conditionality: 'false'
        }
      )
    end
    let(:req3) do
      Inferno::Entities::Requirement.new(
        {
          id: 'sample-criteria@3',
          requirement: 'requirement',
          requirement_set: 'sample-criteria',
          conformance: 'SHALL',
          actors: ['Client'],
          sub_requirements: [],
          conditionality: 'false',
          not_tested_reason: 'Not Tested',
          not_tested_details: 'NOT TESTED DETAILS'
        }
      )
    end

    it 'creates and inserts all requirements from the csv file' do
      expect { repo.insert_from_file(csv) }.to change { repo.all.size }.by(3)
      expect(repo.find(req1.id).to_hash).to eq(req1.to_hash)
      expect(repo.find(req2.id).to_hash).to eq(req2.to_hash)
      expect(repo.find(req3.id).to_hash).to eq(req3.to_hash)
    end
  end

  describe '#complete_requirement_set_requirements' do
    it 'returns all tested requirements matching the specified actor' do
      expect(repo.complete_requirement_set_requirements([complete_requirement_set]).length).to eq(7)
      expect(repo.complete_requirement_set_requirements([empty_requirement_set]).length).to eq(0)
    end
  end

  describe '#filtered_requirement_set_requirements' do
    it 'returns the specified requirements matching the specified actor' do
      expected_ids = [
        'sample-criteria-proposal@1',
        'sample-criteria-proposal@3',
        'sample-criteria-proposal@4',
        'sample-criteria-proposal@5',
        'sample-criteria-proposal@6'
      ]
      found_ids = repo.filtered_requirement_set_requirements([filtered_requriment_set]).map(&:id)

      expect(found_ids).to match_array(expected_ids)
    end
  end

  describe '#add_referenced_requirement_set_requirements' do
    it 'recursively returns referenced requirements matching the specified actor' do
      expected_ids = [
        'sample-criteria-proposal-2@1',
        'sample-criteria-proposal-3@2',
        'sample-criteria-proposal-3@3',
        'sample-criteria-proposal-3@5',
        'sample-criteria-proposal-3@6'
      ]

      requirements = repo.complete_requirement_set_requirements([referenced_requirement_sets.first])
      found_ids = repo.add_referenced_requirement_set_requirements(requirements, referenced_requirement_sets).map(&:id)
      expect(found_ids).to match_array(expected_ids)
    end
  end

  describe '#requirements_for_suite' do
    let(:session) do
      repo_create(
        :test_session,
        suite: 'options',
        suite_options: [Inferno::DSL::SuiteOption.new(id: :ig_version, value: '1')]
      )
    end

    it 'only includes requirements for selected suite options' do
      requirements = repo.requirements_for_suite('options', session.id)

      included_requirement_sets = requirements.map(&:requirement_set)

      expect(included_requirement_sets).to include('sample-criteria-proposal', 'sample-criteria-proposal-3')
      expect(included_requirement_sets).to_not include('sample-criteria-proposal-2')
    end
  end
end
