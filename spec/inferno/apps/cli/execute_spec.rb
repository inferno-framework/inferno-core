require_relative '../../../../lib/inferno/apps/cli/execute.rb'

## TODO REFACTOR ALL THESE TESTS WITH FACTORY BOT

RSpec.describe Inferno::CLI::Execute do  
  let(:instance) { described_class.new }

  describe '#thor_hash_to_inputs_array' do
    let(:hash) { {url: 'https://example.com'} }

    it 'converts hash to array' do
      result = instance.thor_hash_to_inputs_array(hash)
      expect(result.class).to eq(Array)
    end

    it 'returns proper inputs array' do
      result = instance.thor_hash_to_inputs_array(hash)
      expect(result).to eq([{name: :url, value: 'https://example.com'}])
    end
  end

  describe '#create_params' do
    let(:test_suite) { BasicTestSuite::Suite }
    let(:test_sessions_repo) { Inferno::Repositories::TestSessions.new }

    it 'returns test run params' do
      stubbed_instance = instance()
      allow(stubbed_instance).to receive(:options).and_return({inputs: {url: 'https://example.com'}})
      test_session = test_sessions_repo.create(test_suite_id: test_suite.id)

      result = stubbed_instance.create_params(test_session, test_suite)
      expect(result).to eq({test_session_id: test_session.id, test_suite_id: 'basic', inputs: [{name: :url, value: 'https://example.com'}]})
    end
  end

  describe '#serialize' do
    let(:test_suite) { BasicTestSuite::Suite }
    let(:test_session) { Inferno::Repositories::TestSessions.new.create(test_suite_id: test_suite.id) }
    let(:test_run) { Inferno::Repositories::TestRun.new.create({test_session:, test_suite:, status: 'done'}) }
    let(:test_result) do
      Inferno::Repositories::Result.new.create({
        test_suite_id: test_suite.id,
        test_session_id: test_session.id,
        test_run_id: test_run.id,
        result: 'pass',
        result_message: 'This is a mock result'
      })
    end
    let(:test_results) { [test_result, test_result] }

    it 'handles an array of test results without raising exception' do
      expect { instance.serialize(test_results) }.not_to raise_error(StandardError)
    end

    it 'returns legit JSON' do
      expect { JSON.parse(instance.serialize(test_results)) }.not_to raise_error(JSON::ParserError)
      expect { JSON.parse(instance.serialize(test_results)) }.not_to raise_error(JSON::NestingError)
      expect { JSON.parse(instance.serialize(test_results)) }.not_to raise_error(TypeError)
    end
  end

  describe '#verbose_print' do
    it 'outputs when verbose is true' do
      stubbed_instance = instance()
      allow(stubbed_instance).to receive(:options).and_return({verbose: true})

      expect { stubbed_instance.verbose_print('Lorem') }.to output(/Lorem/).to_stdout
    end

    it 'does not output when verbose is false' do
      stubbed_instance = instance()
      allow(stubbed_instance).to receive(:options).and_return({verbose: false})

      expect { stubbed_instance.verbose_print('Lorem') }.not_to output(/.+/).to_stdout
    end
  end

  describe '#verbose_puts' do
    it 'has output ending with \n with when verbose is true' do
      stubbed_instance = instance()
      allow(stubbed_instance).to receive(:options).and_return({verbose: true})

      expect { stubbed_instance.verbose_puts('Lorem') }.to output(/Lorem\n$/).to_stdout
    end
  end

  # TODO: see if I can replace fetch_test_id with .runnable.id
  describe '#fetch_test_id' do
    let(:test_suite) { BasicTestSuite::Suite }
    let(:test_group) { BasicTestSuite::AbcGroup }
    let(:test) { test_group.tests.first }
    let(:test_session) { Inferno::Repositories::TestSessions.new.create(test_suite_id: test_suite.id) }
    let(:test_run) { Inferno::Repositories::TestRun.new.create({test_session:, test_suite:, status: 'done'}) }

    it 'returns suite id if test result belongs to suite' do
      let(:test_result) do
        Inferno::Repositories::Result.new.create({
          test_suite_id: test_suite.id,
          test_session_id: test_session.id,
          test_run_id: test_run.id,
          result: 'pass',
          result_message: 'This is a mock result'
        })
      end

      expect( instance.fetch_test_id(test_result) ).to eq( test_suite.id )
    end

    it 'returns group id if test result belongs to group' do
      let(:test_result) do
        Inferno::Repositories::Result.new.create({
          test_group_id: test_group.id,
          test_session_id: test_session.id,
          test_run_id: test_run.id,
          result: 'pass',
          result_message: 'This is a mock result'
        })
      end

      expect( instance.fetch_test_id(test_result) ).to eq( test_group.id )
    end

    it 'returns test id if test result belongs to test' do
      let(:test_result) do
        Inferno::Repositories::Result.new.create({
          test_id: test.id,
          test_session_id: test_session.id,
          test_run_id: test_run.id,
          result: 'pass',
          result_message: 'This is a mock result'
        })
      end

      expect( instance.fetch_test_id(test_result) ).to eq( test.id )
    end
  end

  describe '#format_messages' do
    let(:test_suite) { BasicTestSuite::Suite }
    let(:test_session) { Inferno::Repositories::TestSessions.new.create(test_suite_id: test_suite.id) }
    let(:test_run) { Inferno::Repositories::TestRun.new.create({test_session:, test_suite:, status: 'done'}) }
    let(:message) { Inferno::Entities::Messages.new }
    let(:test_result) do
      Inferno::Repositories::Result.new.create({
        test_suite_id: test_suite.id,
        test_session_id: test_session.id,
        test_run_id: test_run.id,
        result: 'pass',
        result_message: 'This is a mock result',
        messages: [
          
        ]
      })
    end

    it 'does not omit any data' do
      
    end
  end

  describe '#format_requests' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#format_inputs' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#format_outputs' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#print_error_and_exit' do
    it 'works' do
      let(:mock_error_class) { Class.new(StandardError) }
      let(:mock_error) { mock_error_class.new('mock message') }

    end
  end
end
