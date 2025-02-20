require 'request_helper'
require_relative '../../../lib/inferno/apps/web/router'

RSpec.describe Inferno::DSL::Runnable do
  include Rack::Test::Methods
  include RequestHelpers
  let(:test_suites_repo) { Inferno::Repositories::TestSuites.new }
  let(:test_groups_repo) { Inferno::Repositories::TestGroups.new }

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
    it 'raises an error if the id is longer than 255 characters' do
      expect do
        Class.new(Inferno::Test).id('a' * 256)
      end.to raise_error(Inferno::Exceptions::InvalidRunnableIdException, /length of 255 characters/)
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

      group.remove :def

      expect(group.children.length).to eq(2)
    end
  end

  describe '.replace' do
    let(:group) do
      Class.new(Inferno::TestGroup) do
        test { id :abc }
        test { id :def }
        test { id :ghw }
      end
    end
    let(:id) { 'xyz' }

    before do
      group.id(SecureRandom.uuid)
    end

    it 'replaces a child with a another using its ID' do
      group.test({ id: })
      group.replace(:def, id)

      expect(group.children.length).to eq(3)
      expect(group.children.none? { |child| child.id.to_s.end_with?('def') }).to be true
      expect(group.children[1].id.to_s.end_with?('xyz')).to be true
    end

    it 'applies block configuration to the new child' do
      group.test({ id: })
      group.replace(:def, id) do
        id :new_test_id
      end

      expect(group.children.length).to eq(3)
      expect(group.children[1].id.to_s.end_with?('new_test_id')).to be true
    end

    it 'does not change children if the id to replace is not found' do
      original_children = group.children.dup

      group.replace(id, :ghw)

      expect(group.children).to eq(original_children)
    end

    it 'does not replace if the new child ID is not found in the repository' do
      original_children = group.children.dup

      group.replace(:def, id)

      expect(group.children).to eq(original_children)
    end
  end
end
