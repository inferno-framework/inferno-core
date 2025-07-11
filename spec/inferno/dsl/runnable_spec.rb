require 'request_helper'
require_relative '../../../lib/inferno/apps/web/router'

RSpec.describe Inferno::DSL::Runnable do
  include Rack::Test::Methods
  include RequestHelpers
  let(:test_suites_repo) { Inferno::Repositories::TestSuites.new }
  let(:test_groups_repo) { Inferno::Repositories::TestGroups.new }
  let(:tests_repo) { Inferno::Repositories::Tests.new }

  describe '.resume_test_route' do
    let(:test_suite) { test_suites_repo.find('demo') }
    let(:test_group) { test_groups_repo.find('demo-wait_group') }
    let(:wait_test) { test_group.tests[1] }
    let(:test_session) { repo_create(:test_session, test_suite_id: test_suite.id) }
    let!(:test_run) do
      repo_create(
        :test_run,
        test_session_id: test_session.id,
        runnable: { test_group_id: test_group.id },
        identifier: 'IDENTIFIER',
        status: 'waiting',
        wait_timeout: Time.now + 300.seconds
      )
    end

    let!(:result) do
      repo_create(
        :result,
        test_run_id: test_run.id,
        runnable: wait_test.reference_hash,
        result_message: 'waiting for incoming request',
        result: 'wait'
      )
    end

    context 'when the identifier does not match a test run' do
      it 'renders a 500 error' do
        get '/custom/demo/resume?xyz=BAD_IDENTIFIER'
        expect(last_response.status).to eq(500)
      end
    end

    context 'when the wait timeout has been passed' do
      it 'renders a 500 error' do
        Inferno::Repositories::TestRuns.new.update(test_run.id, wait_timeout: Time.now - 5.seconds)
        get '/custom/demo/resume?xyz=IDENTIFIER'
        expect(last_response.status).to eq(500)
      end
    end

    context 'when a matching test run is found' do
      it 'redirects the user to the waiting group' do
        get '/custom/demo/resume?xyz=IDENTIFIER'

        expect(last_response.status).to eq(302)

        location_header = last_response.get_header('location')

        expect(location_header).to eq("http://localhost:4567/test_sessions/#{test_session.id}##{test_group.id}")
      end

      it 'updates the waiting test result' do
        get '/custom/demo/resume?xyz=IDENTIFIER'

        updated_result = Inferno::Repositories::Results.new.find(result.id)

        expect(updated_result.result).to eq('pass')
        expect(updated_result.result_message).to be_nil
      end

      it 'updates the waiting test run' do
        get '/custom/demo/resume?xyz=IDENTIFIER'

        updated_run = Inferno::Repositories::TestRuns.new.find(test_run.id)

        expect(updated_run.status).to eq('done')
        expect(updated_run.identifier).to be_nil
      end

      it 'results in a fail when fail result is specified' do
        get '/custom/demo/resume_fail?xyz=IDENTIFIER'

        updated_result = Inferno::Repositories::Results.new.find(result.id)

        expect(updated_result.result).to eq('fail')
      end

      it 'results in a skip when skip result is specified' do
        get '/custom/demo/resume_skip?xyz=IDENTIFIER'

        updated_result = Inferno::Repositories::Results.new.find(result.id)

        expect(updated_result.result).to eq('skip')
      end

      it 'results in an omit when omit result is specified' do
        get '/custom/demo/resume_omit?xyz=IDENTIFIER'

        updated_result = Inferno::Repositories::Results.new.find(result.id)

        expect(updated_result.result).to eq('omit')
      end

      it 'results in a cancel when cancel result is specified' do
        get '/custom/demo/resume_cancel?xyz=IDENTIFIER'

        updated_result = Inferno::Repositories::Results.new.find(result.id)

        expect(updated_result.result).to eq('cancel')
      end
    end
  end

  describe '.test_count' do
    it 'returns 1 for a test' do
      klass = Class.new(Inferno::Entities::Test)

      expect(klass.test_count).to eq(1)
    end

    it 'returns the number of tests in a non-nested group' do
      group = test_groups_repo.find('DemoIG_STU1::DemoGroup')

      expect(group.test_count).to eq(group.all_children.length)
    end

    it 'returns the total number of tests in a nested group' do
      base_group = test_groups_repo.find('DemoIG_STU1::DemoGroup')
      parent_group = test_groups_repo.find('demo-repetitive_group')

      expect(parent_group.test_count).to eq(base_group.test_count * 2)
    end

    it 'returns the total number of tests in a suite' do
      suite = test_suites_repo.find('demo')

      expected_count = suite.groups.reduce(0) { |sum, group| sum + group.test_count }

      expect(suite.test_count).to eq(expected_count)
    end

    context 'with suite options' do
      let(:suite) { OptionsSuite::Suite }
      let(:v1_group) { OptionsSuite::V1Group }
      let(:v2_group) { OptionsSuite::V2Group }

      it 'only counts the included runnables' do
        total_count = suite.test_count
        v1_count = v1_group.test_count + 1
        v2_count = v2_group.test_count + 1
        v1_option = Inferno::DSL::SuiteOption.new(id: :ig_version, value: '1')
        v2_option = Inferno::DSL::SuiteOption.new(id: :ig_version, value: '2')

        expect(suite.test_count([v1_option])).to eq(total_count - v2_count)
        expect(suite.test_count([v2_option])).to eq(total_count - v1_count)
      end
    end
  end

  describe '.user_runnable?' do
    let(:run_as_group_examples) { test_groups_repo.find('demo-run_as_group_examples') }

    it 'sets user_runnable on groups and tests to true by default' do
      example_test_group = Class.new(Inferno::Entities::TestGroup)
      example_test_group.test 'test' do
        input :a
      end
      expect(example_test_group.user_runnable?).to be(true)
      expect(example_test_group.tests.first.user_runnable?).to be(true)
    end

    it 'sets user_runnable on groups to true if not under groups set to run_as_group' do
      expect(run_as_group_examples.groups.first.user_runnable?).to be(true)
    end

    it 'sets user_runnable on groups to false if under groups set to run_as_group' do
      expect(run_as_group_examples.groups.first.groups.first.user_runnable?).to be(false)
      expect(run_as_group_examples.groups.first.groups.second.user_runnable?).to be(false)
    end

    it 'sets user_runnable on tests two levels under groups that are run_as_group to be false' do
      expect(run_as_group_examples.groups.first.groups.first.tests.first.user_runnable?).to be(false)
      expect(run_as_group_examples.groups.first.groups.second.tests.first.user_runnable?).to be(false)
    end

    it 'sets user_runnable on tests immediately under groups that are run_as_group to be false' do
      expect(run_as_group_examples.groups.second.tests.first.user_runnable?).to be(false)
    end
  end

  describe '.id' do
    it 'sets a shortened database_id if the id is longer than 255 characters' do
      long_id = 'a' * 256
      test = Class.new(Inferno::Test) do
        id long_id
      end

      expect(test.id).to eq(long_id)
      expect(test.database_id).to_not eq(long_id)
      expect(test.database_id.length).to be <= 255
    end
  end

  describe '.remove' do
    it 'removes a child' do
      group = Class.new(Inferno::TestGroup) do
        id :remove_group

        test { id :abc }
        test { id :def }
        test { id :ghw }
      end

      full_id = group.children[1].id
      group.remove :def

      expect(group.children.length).to eq(2)
      expect(tests_repo.find(full_id)).to be_nil
    end
  end

  describe '.reorder' do
    let(:group) do
      Class.new(Inferno::TestGroup) do
        test { id :abc }
        test { id :def }
        test { id :ghw }
      end
    end

    before do
      group.id(SecureRandom.uuid)
    end

    it 'moves a child to a new position within bounds' do
      group.reorder(:def, 0)

      expect(group.children.map(&:id)).to contain_exactly(
        a_string_ending_with('def'),
        a_string_ending_with('abc'),
        a_string_ending_with('ghw')
      )
    end

    it 'raises an error if the child ID is not found' do
      expect do
        group.reorder(:test_id, 1)
      end.to raise_error(Inferno::Exceptions::RunnableChildNotFoundException, /Could not find a child with an ID/)
    end

    it 'logs an error if new_index is out of range' do
      allow(Inferno::Application[:logger]).to receive(:error)

      group.reorder(:def, 10)

      expect(Inferno::Application[:logger]).to have_received(:error).with(/Error trying to reorder children for .*:/)
      expect(group.children.map(&:id)).to contain_exactly(
        a_string_ending_with('abc'),
        a_string_ending_with('def'),
        a_string_ending_with('ghw')
      )
    end
  end

  describe '.replace' do
    let(:test_group) { test_groups_repo.find('auth_info-auth_info_demo') } # 'replace-repetitive_group'

    before do
      test_group.id(SecureRandom.uuid)
    end

    it 'replaces a child with a new one using its ID' do
      child = test_group.children.first
      global_id = child.id.split('-').last
      test_group.replace global_id, 'DemoIG_STU1::DemoGroup'

      expect(test_group.children.length).to eq(2)
      expect(test_group.children.none? { |c| c.id.to_s.end_with?('DEF') }).to be true
      expect(test_group.children[0].id.to_s.end_with?('DemoIG_STU1::DemoGroup')).to be true
      expect(test_groups_repo.find(child.id)).to be_nil
      expect(child.children.filter_map { |c| tests_repo.find(c.id) }).to be_empty
    end

    it 'applies block configuration to the new child when block given' do
      child = test_group.children.first
      global_id = child.id.split('-').last
      test_group.replace global_id, 'DemoIG_STU1::DemoGroup' do
        id :new_id
      end

      expect(test_group.children.length).to eq(2)
      expect(test_group.children[0].id.to_s.end_with?('new_id')).to be true
      expect(test_groups_repo.find(child.id)).to be_nil
      expect(child.children.filter_map { |c| tests_repo.find(c.id) }).to be_empty
    end

    it 'raises an error if the id to replace is not found' do
      expect do
        test_group.replace 'test_id', 'DemoIG_STU1::DemoGroup'
      end.to raise_error(Inferno::Exceptions::RunnableChildNotFoundException, /Could not find a child with an ID/)
    end
  end

  describe '.verifies_requirements' do
    let(:example_test_group) { Class.new(Inferno::Entities::TestGroup) }

    it 'sets ids of requirements verified by a runnable' do
      example_test_group.verifies_requirements 'example_requirement'

      expect(example_test_group.verifies_requirements.length).to be(1)
      expect(example_test_group.verifies_requirements).to include('example_requirement')
    end

    it 'returns an empty array when no requirement_ids are passed and @requirement_ids not set' do
      example_test_group.test 'test' do
        id 'rand_test'
      end

      expect(example_test_group.verifies_requirements).to eq([])
    end
  end
end
