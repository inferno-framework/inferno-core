# frozen_string_literal: true

require 'pastel'
require 'active_support'
require_relative '../web/serializers/test_run'
require_relative '../web/serializers/result'

module Inferno
  module CLI
    class Execute

      def self.suppress_output
        begin
          original_stderr = $stderr.clone
          original_stdout = $stdout.clone
          $stderr.reopen(File.new('/dev/null', 'w'))
          $stdout.reopen(File.new('/dev/null', 'w'))
          retval = yield
        rescue StandardError => e
          $stdout.reopen(original_stdout)
          $stderr.reopen(original_stderr)
          raise e
        ensure
          $stdout.reopen(original_stdout)
          $stderr.reopen(original_stderr)
        end
        retval
      end

      # Inferno boot flow triggers migration and logger outputs it
      # I would be allow this in verbose mode but definitely not for JSON output
      suppress_output{ require_relative '../../../inferno' }

      COLOR = Pastel.new
      CHECKMARK = "\u2713"

      include Import[
                test_sessions_repo: 'inferno.repositories.test_sessions',
                session_data_repo: 'inferno.repositories.session_data',
                test_runs_repo: 'inferno.repositories.test_runs'
              ]

      attr_accessor :options

      # TODO factorize into some helper/util with hanami controller
      def verify_runnable(runnable, inputs, selected_suite_options)
        missing_inputs = runnable&.missing_inputs(inputs, selected_suite_options)
        user_runnable = runnable&.user_runnable?
        raise Inferno::Exceptions::RequiredInputsNotFound, missing_inputs if missing_inputs&.any?
        raise Inferno::Exceptions::NotUserRunnableException unless user_runnable
      end

      # TODO likewise
      def persist_inputs(params, test_run)
        available_inputs = test_run.runnable.available_inputs
        params[:inputs]&.each do |input_params|
          input =
            available_inputs
              .find { |_, runnable_input| runnable_input.name == input_params[:name] }
              &.last

          if input.nil?
            Inferno::Application['logger'].warn(
              "Unknown input `#{input_params[:name]}` for #{test_run.runnable.id}: #{test_run.runnable.title}"
            )
            next
          end

          session_data_repo.save(
            test_session_id: test_run.test_session_id,
            name: input.name,
            value: input_params[:value],
            type: input.type
          )
        end
      end

      def run(options)
        puts ''
        puts '=========================================='
        puts "Testing #{options[:suite]} Suite"
        puts '=========================================='

        self.options = options
        verbose_puts "options:", self.options

        Inferno::Application.start(:suites)

        suite = Inferno::Repositories::TestSuites.new.find(options[:suite])
        raise StandardError, "Suite #{options[:suite]} not found" if suite.nil?

        test_session = test_sessions_repo.create({test_suite_id: suite.id}) # TODO add suite options

        verify_runnable(
          test_runs_repo.build_entity(create_params(test_session,suite)).runnable,
          thor_hash_to_inputs_array(options[:inputs]),
          test_session.suite_options
        )

        test_run = test_runs_repo.create(
          create_params(test_session,suite).merge({status: 'queued'})
        )

        persist_inputs(create_params(test_session, suite), test_run)

        puts "Running tests. This may take a while..."
        Jobs.perform(Jobs::ExecuteTestRun, test_run.id, force_synchronous: true)

        results = test_runs_repo.results_for_test_run(test_run.id)&.reverse
        verbose_puts '=========================================='
        verbose_puts "JSON Test Results:"
        verbose_puts '=========================================='
        verbose_puts serialize(results)
        verbose_puts '=========================================='

        puts '=========================================='
        puts "Colored Test Results:"
        puts '=========================================='
        results.each do |result|
          print fetch_test_id(result), ": "
          case result.result
          when 'pass'
            print COLOR.bold.green(CHECKMARK, ' pass')
          when 'fail'
            print COLOR.bold.red 'X fail'
          when 'skip'
            print COLOR.yellow '* skip'
          when 'omit'
            print COLOR.blue '* omit'
          when 'error'
            print COLOR.magenta 'X error'
          when 'wait'
            # This may be dead code with synchronous test execution
            print '. wait'
          when 'cancel'
            print COLOR.red 'X cancel'
          else
            # TODO strict behavior or no?
            #raise StandardError.new, "Unrecognized result #{result.result}" # strict
            print '- unknown'                                                # unstrict
          end
          puts ''
          verbose_puts "\tsummary: ",  result.result_message
          verbose_puts "\tmessages: ", print_messages(result)
          verbose_puts "\trequests: ", print_requests(result)
        end
        puts '=========================================='


      rescue Sequel::ValidationFailed, Sequel::ForeignKeyConstraintViolation,
             Inferno::Exceptions::RequiredInputsNotFound,
             Inferno::Exceptions::NotUserRunnableException => e
        $stderr.puts COLOR.red "Error: #{e.full_message}"
        # TODO: use Application Logger?
        exit(1)
      rescue StandardError => e
        $stderr.puts COLOR.red "Error: #{e.full_message}"
        exit(1)
      end

      def thor_hash_to_inputs_array(hash)
        hash.to_a.map{|pair| {name: pair[0], value: pair[1]}}
      end

      def create_params(test_session, suite)
        {
          test_session_id: test_session.id,
          test_suite_id: suite.id,
          inputs: thor_hash_to_inputs_array(self.options[:inputs])
        }
      end

      def serialize(entity)
        case entity.class.to_s
        when 'Array'
          JSON.pretty_generate entity.map{ |item| JSON.parse serialize(item) }
        when ->(x) { defined?(x.constantize) && defined?("Inferno::Web::Serializers::#{x.split('::').last}".constantize) }
          "Inferno::Web::Serializers::#{entity.class.to_s.split('::').last}".constantize.render(entity)
        else
          raise StandardError, "CLI does not know how to serialize #{entity.class}"
        end
      end

      def verbose_print(*args)
        print(COLOR.dim(*args)) if self.options[:verbose]
      end

      def verbose_puts(*args)
        args.push("\n")
        verbose_print(*args)
      end

      def fetch_test_id(result)
        [result.test_id, result.test_group_id, result.test_suite_id].find { |x| x.presence }
      end

      def print_messages(result)
        result.messages.map do |message|
          "\n\t\t" + message.type + ": " + message.message
        end
      end

      def print_requests(result)
        result.requests.map do |req_res|
          "\n\t\t" + req_res.status.to_s + ' ' + req_res.verb.upcase + ' ' + req_res.url
        end
      end
    end
  end
end
