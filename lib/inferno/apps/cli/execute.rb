require 'pastel'
require 'active_support'
require_relative '../../utils/verify_runnable'
require_relative '../../utils/persist_inputs'
require_relative 'execute/console_outputter'

module Inferno
  module CLI
    class Execute
      include ::Inferno::Utils::VerifyRunnable
      include ::Inferno::Utils::PersistInputs

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
          if all_selected_groups_and_tests.empty?
            test_run = create_test_run(suite)
            run_one(suite, test_run)

            results = test_runs_repo.results_for_test_run(test_run.id)
          else
            all_selected_groups_and_tests.each do |runnable|
              test_run = create_test_run(runnable)
              run_one(runnable, test_run)

              results += test_runs_repo.results_for_test_run(test_run.id)
            end
          end
        end

        # User may enter duplicate runnables, in which case this prevents a bug of extraneous results
        results.uniq!(&:id).sort! { |result, other| result.runnable.short_id <=> other.runnable.short_id }

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
        # TODO: swap outputter based on options
        @outputter ||= Inferno::CLI::Execute::ConsoleOutputter.new
      end

      def all_selected_groups_and_tests
        @all_selected_groups_and_tests ||= runnables_by_short_id + groups + tests
      end

      def run_one(runnable, test_run)
        verify_runnable(
          runnable,
          thor_hash_to_inputs_array(options[:inputs]),
          test_session.suite_options
        )

        persist_inputs(session_data_repo, create_params(test_session, suite), test_run)

        dispatch_job(test_run)
      end

      def suite
        @suite ||= Inferno::Repositories::TestSuites.new.find(options[:suite])

        raise StandardError, "Test suite #{options[:suite]} not found" if @suite.nil?

        @suite
      end

      def test_runs_repo
        @test_runs_repo ||= Inferno::Repositories::TestRuns.new
      end

      def create_test_run(runnable)
        test_runs_repo.create(
          create_params(test_session, runnable).merge({ status: 'queued' })
        )
      end

      def results_repo
        @results_repo ||= Inferno::Repositories::Results.new
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

      def runnables_by_short_id
        return [] if options[:short_ids].blank?

        @runnables_by_short_id ||= options[:short_ids]&.map { |short_id| find_by_short_id(:group_or_test, short_id) }
      end

      def groups
        return [] if options[:groups].blank?

        @groups ||= options[:groups]&.map { |short_id| find_by_short_id(:group, short_id) }
      end

      def tests
        return [] if options[:tests].blank?

        @tests ||= options[:tests]&.map { |short_id| find_by_short_id(:test, short_id) }
      end

      def find_by_short_id(repo_symbol, short_id)
        repo_symbol_to_array(repo_symbol).each do |repo|
          repo.all.each do |entity|
            return entity if short_id == entity.short_id && suite.id == entity.suite.id
          end
        end
        raise StandardError, "#{repo_symbol.to_s.humanize} #{short_id} not found."
      end

      def repo_symbol_to_array(repo_symbol)
        case repo_symbol
        when :group
          [test_groups_repo]
        when :test
          [tests_repo]
        when :group_or_test
          [test_groups_repo, tests_repo]
        else
          raise StandardError, "Unrecognized repo_symbol #{repo_symbol} for `find_by_short_id`"
        end
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
        if runnable < Inferno::TestSuite
          :suite
        elsif runnable < Inferno::TestGroup
          :group
        elsif runnable < Inferno::Test
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
