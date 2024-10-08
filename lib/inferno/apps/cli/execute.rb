#require 'pastel'
require 'active_support'
require 'dry/inflector'
require_relative '../../utils/verify_runnable'
require_relative '../../utils/persist_inputs'

Dir[File.join(__dir__, 'execute', '*_outputter.rb')].each { |outputter| require outputter }

#require_relative 'execute/quiet_outputter'
#require_relative 'execute/json_outputter'
#require_relative 'execute/console_outputter'
#require_relative 'execute/plain_outputter'

module Inferno
  module CLI
    class Execute
      include ::Inferno::Utils::VerifyRunnable
      include ::Inferno::Utils::PersistInputs

      INFLECTOR = Dry::Inflector.new do |inflections|
        inflections.acronym "JSON"
      end

      OUTPUTTER_WHITELIST = %w[console plain json quiet]

      attr_accessor :options

      def self.suppress_output
        begin
          original_stdout = $stdout.clone
          $stdout.reopen(File.new(File::NULL, 'w+'))
          retval = yield
        ensure
          $stdout.reopen(original_stdout)
        end
        retval
      end

      def self.boot_full_inferno
        ENV['NO_DB'] = 'false'

        # Inferno boot flow triggers migration and logger outputs it
        Inferno::CLI::Execute.suppress_output { require_relative '../../../inferno' }

        Inferno::Application.start(:executor)
      end

      def run(options)
        print_help_and_exit if options[:help]

        self.options = options

        outputter.print_start_message(options)

        results = []
        outputter.print_around_run(options) do
          if selected_runnables.empty?
            run_one(suite)
            results = test_runs_repo.results_for_test_run(test_run(suite).id).reverse
          else
            selected_runnables.each do |runnable|
              run_one(runnable)
              results += test_runs_repo.results_for_test_run(test_run(runnable).id).reverse
            end
          end
        end

        outputter.print_results(options, results)

        outputter.print_end_message(options)

        exit(0) if results.all? { |result| result.result == 'pass' }

        # exit(1) is for Thor failures
        # exit(2) is for shell builtin failures
        exit(3)
      rescue Sequel::ValidationFailed => e
        print_error_and_exit(e, 4)
      rescue Sequel::ForeignKeyConstraintViolation => e
        print_error_and_exit(e, 5)
      rescue Inferno::Exceptions::RequiredInputsNotFound => e
        print_error_and_exit(e, 6)
      rescue Inferno::Exceptions::NotUserRunnableException => e
        print_error_and_exit(e, 7)
      rescue StandardError => e
        print_error_and_exit(e, 8)
      end

      def print_help_and_exit
        puts `NO_DB=true bundle exec inferno help execute`
        exit(0)
      end

      def outputter
        raise StandardError, "Unrecognized outputter #{options[:outputter]}" unless OUTPUTTER_WHITELIST.include? options[:outputter]

        @outputter ||= INFLECTOR.constantize("Inferno::CLI::Execute::#{INFLECTOR.camelize(options[:outputter])}Outputter").new
=begin
        @outputter ||= case options[:outputter]
            when 'quiet'
              QuietOutputter.new
            when 'json'
              JSONOutputter.new
            when 'plain'
              PlainOutputter.new
            when 'console'
              ConsoleOutputter.new
            else
              raise StandardError, "Unrecognized outputter #{options[:outputter]}"
            end
=end
      end

      def selected_runnables
        groups + tests
      end

      def run_one(runnable)
        verify_runnable(
          suite,
          thor_hash_to_inputs_array(options[:inputs]),
          test_session.suite_options
        )

        persist_inputs(session_data_repo, create_params(test_session, suite), test_run(runnable))

        dispatch_job(test_run(runnable))
      end

      def suite
        @suite ||= Inferno::Repositories::TestSuites.new.find(options[:suite])

        raise StandardError, "Test suite #{options[:suite]} not found" if @suite.nil?

        @suite
      end

      def test_runs_repo
        @test_runs_repo ||= Inferno::Repositories::TestRuns.new
      end

      def test_run(runnable_param)
        @test_runs ||= {}

        @test_runs[runnable_param] ||= test_runs_repo.create(
          create_params(test_session, runnable_param).merge({ status: 'queued' })
        )

        @test_runs[runnable_param]
      end

      def test_groups_repo
        @test_groups_repo ||= Inferno::Repositories::TestGroups.new
      end

      def tests_repo
        @tests_repo ||= Inferno::Repositories::Tests.new
      end

      def test_sessions_repo
        @test_sessions_repo ||= Inferno::Repositories::TestSessions.new
      end

      def session_data_repo
        @session_data_repo ||= Inferno::Repositories::SessionData.new
      end

      def test_session
        @test_session ||= test_sessions_repo.create({
                                                      test_suite_id: suite.id,
                                                      suite_options: thor_hash_to_suite_options_array(
                                                        options[:suite_options]
                                                      )
                                                    })
      end

      def create_params(test_session, runnable)
        {
          test_session_id: test_session.id,
          runnable_id_key(runnable) => runnable.id,
          inputs: thor_hash_to_inputs_array(options[:inputs])
        }
      end

      def dispatch_job(test_run)
        # TODO: move suppression to outputter? better suppression?
        if options[:verbose]
          Jobs.perform(Jobs::ExecuteTestRun, test_run.id, force_synchronous: true)
        else
          Inferno::CLI::Execute.suppress_output do
            Jobs.perform(Jobs::ExecuteTestRun, test_run.id, force_synchronous: true)
          end
        end
      end

      def groups
        return [] if options[:groups].blank?

        @groups ||= options[:groups]&.map { |short_id| find_by_short_id(test_groups_repo, short_id) }
      end

      def tests
        return [] if options[:tests].blank?

        @tests ||= options[:tests]&.map { |short_id| find_by_short_id(tests_repo, short_id) }
      end

      def find_by_short_id(repo, short_id)
        repo.all.each do |entity|
          return entity if short_id == entity.short_id && suite.id == entity.suite.id
        end
        raise StandardError, "Group or test #{short_id} not found"
      end

      def thor_hash_to_suite_options_array(hash = {})
        hash.to_a.map { |pair| Inferno::DSL::SuiteOption.new({ id: pair[0], value: pair[1] }) }
      end

      def thor_hash_to_inputs_array(hash = {})
        hash.to_a.map { |pair| { name: pair[0], value: pair[1] } }
      end

      def print_error_and_exit(err, code)
        outputter.print_error(options || {}, err)
      rescue StandardError => e
        puts "Caught exception #{e} while printing exception #{err}. Exiting."
      ensure
        exit(code)
      end

      def runnable_type(runnable)
        if Inferno::TestSuite.subclasses.include? runnable
          :suite
        elsif Inferno::TestGroup.subclasses.include? runnable
          :group
        elsif Inferno::Test.subclasses.include? runnable
          :test
        else
          raise StandardError, "Unidentified runnable #{runnable}"
        end
      end

      def runnable_id_key(runnable)
        case runnable_type(runnable)
        when :suite
          :test_suite_id
        when :group
          :test_group_id
        else
          :test_id
        end
      end
    end
  end
end
