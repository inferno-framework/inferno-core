# frozen_string_literal: true

require 'pastel'
require 'active_support'
require_relative '../web/serializers/test_run'
require_relative '../web/serializers/result'
require_relative '../../utils/verify_runnable'
require_relative '../../utils/persist_inputs'

module Inferno
  module CLI
    class Execute
      include ::Inferno::Utils::VerifyRunnable
      include ::Inferno::Utils::PersistInputs

      COLOR = Pastel.new
      CHECKMARK = "\u2713"
      BAR = '=========================================='

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
        print_start_message
        verbose_puts 'options:', self.options

        test_sessions_repo = Inferno::Repositories::TestSessions.new
        session_data_repo = Inferno::Repositories::SessionData.new
        test_runs_repo = Inferno::Repositories::TestRuns.new

        test_session = test_sessions_repo.create({
                                                   test_suite_id: runnable.suite.id,
                                                   suite_options: thor_hash_to_suite_options_array(
                                                     options[:suite_options]
                                                   )
                                                 })

        verify_runnable(
          runnable,
          thor_hash_to_inputs_array(options[:inputs]),
          test_session.suite_options
        )

        test_run = test_runs_repo.create(
          create_params(test_session, runnable).merge({ status: 'queued' })
        )

        persist_inputs(session_data_repo, create_params(test_session, runnable), test_run)

        puts 'Running tests. This may take a while...' # TODO: spinner/progress bar

        # TODO: hijack logger instead of using this if-case
        if options[:verbose]
          Jobs.perform(Jobs::ExecuteTestRun, test_run.id, force_synchronous: true)
        else
          Inferno::CLI::Execute.suppress_output do
            Jobs.perform(Jobs::ExecuteTestRun, test_run.id, force_synchronous: true)
          end
        end

        results = test_runs_repo.results_for_test_run(test_run.id).reverse

        verbose_print_json_results(results)
        print_color_results(results)

        if results.find do |result|
             result.send(runnable_id_key) == options[runnable_type.to_sym]
           end.result == 'pass'
          exit(0)
        end

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

      def print_start_message
        puts ''
        puts BAR
        puts "Testing #{options[:suite] || options[:group] || options[:test]}"
        puts BAR
      end

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

      def thor_hash_to_suite_options_array(hash = {})
        hash.to_a.map { |pair| Inferno::DSL::SuiteOption.new({ id: pair[0], value: pair[1] }) }
      end

      def thor_hash_to_inputs_array(hash = {})
        hash.to_a.map { |pair| { name: pair[0], value: pair[1] } }
      end

      def create_params(test_session, runnable)
        {
          test_session_id: test_session.id,
          runnable_id_key => runnable.id,
          inputs: thor_hash_to_inputs_array(options[:inputs])
        }
      end

      def serialize(entity)
        case entity.class.to_s
        when 'Array'
          JSON.pretty_generate(entity.map { |item| JSON.parse serialize(item) })
        when lambda { |x|
               defined?(x.constantize) && defined?("Inferno::Web::Serializers::#{x.split('::').last}".constantize)
             }
          "Inferno::Web::Serializers::#{entity.class.to_s.split('::').last}".constantize.render(entity)
        else
          raise StandardError, "CLI does not know how to serialize #{entity.class}"
        end
      end

      def verbose_print(*args)
        print(COLOR.dim(*args)) if options[:verbose]
      end

      def verbose_puts(*args)
        args.push("\n")
        verbose_print(*args)
      end

      def format_id(result)
        result.runnable.id
      end

      def format_messages(result)
        result.messages.map do |message|
          "\n\t\t#{message.type}: #{message.message}"
        end.join
      end

      def format_requests(result)
        result.requests.map do |req_res|
          "\n\t\t#{req_res.status} #{req_res.verb.upcase} #{req_res.url}"
        end.join
      end

      def format_session_data(result, attr)
        json = result.send(attr)
        return '' if json.nil?

        JSON.parse(json).map do |hash|
          "\n\t\t#{hash['name']}: #{hash['value']}"
        end.join
      end

      def format_inputs(result)
        format_session_data(result, :input_json)
      end

      def format_outputs(result)
        format_session_data(result, :output_json)
      end

      def format_result(result) # rubocop:disable Metrics/CyclomaticComplexity
        case result.result
        when 'pass'
          COLOR.bold.green(CHECKMARK, ' pass')
        when 'fail'
          COLOR.bold.red 'X fail'
        when 'skip'
          COLOR.yellow '* skip'
        when 'omit'
          COLOR.blue '* omit'
        when 'error'
          COLOR.magenta 'X error'
        when 'wait'
          COLOR.bold '. wait'
        when 'cancel'
          COLOR.red 'X cancel'
        when 'running'
          COLOR.bold '- running'
        else
          raise StandardError.new, "Unrecognized result #{result.result}"
        end
      end

      def verbose_print_json_results(results)
        verbose_puts BAR
        verbose_puts 'JSON Test Results:'
        verbose_puts BAR
        verbose_puts serialize(results)
        verbose_puts BAR
      end

      def print_color_results(results)
        puts BAR
        puts 'Test Results:'
        puts BAR
        results.each do |result|
          print format_id(result), ': ', format_result(result), "\n"
          verbose_puts "\tsummary: ",   result.result_message
          verbose_puts "\tmessages: ",  format_messages(result)
          verbose_puts "\trequests: ",  format_requests(result)
          verbose_puts "\tinputs: ",    format_inputs(result)
          verbose_puts "\toutputs: ",   format_outputs(result)
        end
        puts BAR
      end

      def print_error_and_exit(err, code)
        # TODO: use Application Logger for stderr?
        $stderr.puts COLOR.red "Error: #{err.full_message}" # rubocop:disable Style/StderrPuts # always print this error instead of using `warn`
        exit(code)
      end
    end
  end
end
