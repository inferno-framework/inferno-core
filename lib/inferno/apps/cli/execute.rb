require 'active_support'
require_relative '../../utils/verify_runnable'
require_relative '../../utils/persist_inputs'

Dir[File.join(__dir__, 'execute', '*_outputter.rb')].each { |outputter| require outputter }

module Inferno
  module CLI
    # Execute Inferno tests in the Command Line. A single instance
    # of this class represents a test session, and a single +run+
    # call queue's TestGroups and Tests for execution.
    #
    # The current implementation cannot handle waiting for client
    # requests or SMART launch.
    #
    # @see Inferno::CLI::Main#execute for CLI usage.
    #
    # @example
    #   Inferno::CLI::Execute.new.run({
    #       suite: 'dev_validator_suite',
    #       inputs: {
    #           'patient_id' => '1234321',
    #           'url' => 'https://hapi.fhir.org/baseR4'
    #       },
    #       outputter: 'plain'
    #   })
    class Execute
      include ::Inferno::Utils::VerifyRunnable
      include ::Inferno::Utils::PersistInputs

      OUTPUTTERS = {
        'console' => Inferno::CLI::Execute::ConsoleOutputter,
        'plain' => Inferno::CLI::Execute::PlainOutputter,
        'json' => Inferno::CLI::Execute::JSONOutputter,
        'quiet' => Inferno::CLI::Execute::QuietOutputter
      }.freeze

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

      # TODO: delete or refactor
      # def initialize
      # end

      def run(options)
        print_help_and_exit if options[:help]

        self.options = options

        outputter.print_start_message(self.options)

        load_preset_file_and_set_preset_id
        test_sessions_repo.apply_preset(test_session, options[:preset_id])

        results = []
        outputter.print_around_run(self.options) do
          if all_selected_groups_and_tests.empty?
            test_run = create_test_run(suite)
            run_one(suite, test_run)

            results = test_runs_repo.results_for_test_run(test_run.id)
            results = sort_results(results)
          else
            all_selected_groups_and_tests.each do |runnable|
              test_run = create_test_run(runnable)
              run_one(runnable, test_run)

              results += sort_results(test_runs_repo.results_for_test_run(test_run.id))
            end
          end
        end

        # User may enter duplicate runnables, in which case this prevents a bug of extraneous results
        results.uniq!(&:id)

        outputter.print_results(options, results)
        outputter.print_end_message(options)

        # TODO: respect customized rollups
        exit(0) if Inferno::ResultSummarizer.new(results).summarize == 'pass'

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
        unless OUTPUTTERS.key? options[:outputter]
          raise StandardError,
                "Unrecognized outputter #{options[:outputter]}"
        end

        @outputter ||= OUTPUTTERS[options[:outputter]].new
      end

      def load_preset_file_and_set_preset_id
        return unless options[:preset_file]
        raise StandardError, 'Cannot use `--preset-id` and `--preset-file` options together' if options[:preset_id]

        raise StandardError, "File #{options[:preset_file]} not found" unless File.exist? options[:preset_file]

        options[:preset_id] = JSON.parse(File.read(options[:preset_file]))['id']
        raise StandardError, "Preset #{options[:preset_file]} is missing id. A unique preset id is required for `inferno execute`." if options[:preset_id].nil?

        presets_repo.insert_from_file(options[:preset_file])
      end

      def all_selected_groups_and_tests
        @all_selected_groups_and_tests ||= runnables_by_short_id + groups + tests
      end

      def run_one(runnable, test_run)
        verify_runnable(
          runnable,
          thor_hash_to_inputs_array(all_inputs),
          test_session.suite_options
        )

        persist_inputs(session_data_repo, create_params(test_session, suite), test_run)

        dispatch_job(test_run)
      end

      def all_inputs
        if preset
          # TODO use session and preset processor properly instead of reverse merge
          processed_inputs = Inferno::Utils::PresetProcessor.new(preset, test_session).processed_inputs

          preset_inputs = processed_inputs.map { |hash| [hash[:name], hash[:value]] }.to_h
          
          # XXX DEBUGGING
          puts "====================="
          pp preset_inputs
          puts "====================="

          options.fetch(:inputs, {}).reverse_merge(preset_inputs)
        else
          options.fetch(:inputs, {})
        end
      end

      def preset
        return unless options[:preset_id]

        @preset ||= presets_repo.find(options[:preset_id])

        raise StandardError, "Preset #{options[:preset_id]} not found" if @preset.nil?

        unless presets_repo.presets_for_suite(suite.id).include?(@preset)
          raise StandardError,
                "Preset #{options[:preset_id]} is incompatible with suite #{suite.id}"
        end

        @preset
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

      def presets_repo
        @presets_repo ||= Inferno::Repositories::Presets.new
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
          inputs: thor_hash_to_inputs_array(all_inputs) # XXX
        }
      end

      def dispatch_job(test_run)
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

      def sort_results(results)
        results.sort do |result, other|
          if result.runnable < Inferno::TestSuite
            -1
          elsif other.runnable < Inferno::TestSuite
            1
          else
            result.runnable.short_id <=> other.runnable.short_id
          end
        end
      end
    end
  end
end
