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
          if runnables.empty? # TODO better cond?
            # TODO factorize:
            verify_runnable(
              suite,
              thor_hash_to_inputs_array(options[:inputs]),
              test_session.suite_options
            )

            persist_inputs(session_data_repo, create_params(test_session, suite), test_run(suite)) # NOTE: diff

            dispatch_job(test_run(suite))

            results = test_runs_repo.results_for_test_run(test_run(suite).id).reverse
          else
            runnables.each do |runnable|
                verify_runnable(
                  suite,
                  thor_hash_to_inputs_array(options[:inputs]),
                  test_session.suite_options
                )

                persist_inputs(session_data_repo, create_params(test_session, suite), test_run(runnable))

                dispatch_job(test_run(runnable))
                results += test_runs_repo.results_for_test_run(test_run(runnable).id).reverse # NOTE: diff
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

      def dispatch_job(test_run)
        # TODO: move suppression to outputter? better suppresion?
        if options[:verbose]
          Jobs.perform(Jobs::ExecuteTestRun, test_run.id, force_synchronous: true)
        else
          Inferno::CLI::Execute.suppress_output do
            Jobs.perform(Jobs::ExecuteTestRun, test_run.id, force_synchronous: true)
          end
        end
      end

      def test_sessions_repo
        @test_sessions_repo ||= Inferno::Repositories::TestSessions.new
      end

      def session_data_repo
        @session_data_repo ||= Inferno::Repositories::SessionData.new
      end

      def test_runs_repo
        @test_runs_repo ||= Inferno::Repositories::TestRuns.new
      end

      def test_session
        @test_session ||= test_sessions_repo.create({
                                                      test_suite_id: suite.id,
                                                      suite_options: thor_hash_to_suite_options_array(
                                                        options[:suite_options]
                                                      )
                                                    })
      end

      def test_run(runnable_param)
        @test_runs ||= {}

        @test_runs[runnable_param] ||= test_runs_repo.create(
          create_params(test_session, runnable_param).merge({ status: 'queued' })
        )

        @test_runs[runnable_param]
      end

      # TODO run per
      def create_params(test_session, runnable)
        {
          test_session_id: test_session.id,
          runnable_id_key(runnable) => runnable.id,
          inputs: thor_hash_to_inputs_array(options[:inputs])
        }
      end

      def suite
        @suite ||= Inferno::Repositories::TestSuites.new.find(options[:suite])

        raise StandardError, "Test suite #{options[:suite]} not found" if @suite.nil?

        @suite
      end

      def groups
        @groups ||= Inferno::Repositories::TestGroups.new.all.select do |group|
          options[:groups]&.include?(group.short_id) && group.suite.id == suite.id
        end
      end

      def tests
        @tests ||= Inferno::Repositories::Tests.new.all.select do |test|
          options[:tests]&.include?(test.short_id) && test.suite.id == suite.id
        end
      end

      def runnables
        groups + tests
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

=begin
      # TODO: redo/rm this for short ids in groups and tests
      def runnable
        @runnable ||=
          case runnable_type
          when 'suite'
            Inferno::Repositories::TestSuites.new.find(options[:suite])
          when 'group'
            Inferno::Repositories::TestGroups.new.find(options[:group])
          when 'test'
            Inferno::Repositories::Tests.new.find(options[:test])
          end

        raise StandardError, "#{runnable_type.capitalize} #{options[runnable_type.to_sym]} not found" if @runnable.nil?

        @runnable
      end

      def runnable_type
        @runnable_type ||=
          if options[:suite]
            'suite'
          elsif options[:group]
            'group'
          elsif options[:test]
            'test'
          else
            raise StandardError, 'No suite, group, or test id provided'
          end
      end

      def runnable_id_key
        case runnable_type&.to_sym
        when :suite
          :test_suite_id
        when :group
          :test_group_id
        when :test
          :test_id
        else
          raise StandardError, "Unrecognized runnable type #{runnable_type}"
        end
      end
=end

      def thor_hash_to_suite_options_array(hash = {})
        hash.to_a.map { |pair| Inferno::DSL::SuiteOption.new({ id: pair[0], value: pair[1] }) }
      end

      def thor_hash_to_inputs_array(hash = {})
        hash.to_a.map { |pair| { name: pair[0], value: pair[1] } }
      end


      def print_error_and_exit(err, code)
        # TODO FIXME
        begin
          outputter.print_error(options || {}, err)
        rescue Exception => outputter_err
          $stderr.puts "Caught exception #{outputter_err} while printing exception #{err}. Exiting."
        ensure
          exit(code)
        end
      end

      def outputter
        # TODO: swap outputter based on options
        @outputter ||= Inferno::CLI::Execute::ConsoleOutputter.new
      end
    end
  end
end
