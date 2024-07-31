# frozen_string_literal: true

require 'pastel'
require 'active_support'
require_relative '../../../inferno'
require_relative '../web/serializers/test_run'
require_relative '../web/serializers/result'

module Inferno
  module CLI
    class Execute

      COLOR = Pastel.new

      include Import[
                test_sessions_repo: 'inferno.repositories.test_sessions',
                session_data_repo: 'inferno.repositories.session_data',
                test_runs_repo: 'inferno.repositories.test_runs'
              ]

      attr_accessor :options

      def verify_runnable(runnable, inputs, selected_suite_options)
        missing_inputs = runnable&.missing_inputs(inputs, selected_suite_options)
        user_runnable = runnable&.user_runnable?
        raise Inferno::Exceptions::RequiredInputsNotFound, missing_inputs if missing_inputs&.any?
        raise Inferno::Exceptions::NotUserRunnableException unless user_runnable
      end

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

      ## MAIN
      def run(options)
        puts ''
        puts '=========================================='
        puts " Testing #{options[:suite]} Suite"
        puts '=========================================='

        self.options = options
        verbose_puts "In verbose mode"

        # TODO: hijack Application logger?
        Inferno::Application.start(:suites)        

        suite = Inferno::Repositories::TestSuites.new.find(options[:suite])
        raise StandardError, "Suite #{options[:suite]} not found" if suite.nil?

        test_session = test_sessions_repo.create({test_suite_id: suite.id}) # TODO add suite options

        verify_runnable(
          test_runs_repo.build_entity({
            test_session_id: test_session.id,
            test_suite_id: suite.id,
            inputs: thor_hash_to_inputs_array(options[:inputs])
          }).runnable,
          thor_hash_to_inputs_array(options[:inputs]),
          test_session.suite_options
        )

        test_run = test_runs_repo.create({
          test_session_id: test_session.id,
          test_suite_id: suite.id,
          inputs: thor_hash_to_inputs_array(options[:inputs]),
          status: 'queued'
        })

        persist_inputs({test_session_id: test_session.id, test_suite_id: suite.id, inputs: thor_hash_to_inputs_array(options[:inputs])}, test_run)

        Jobs.perform(Jobs::ExecuteTestRun, test_run.id)

        # TODO how to properly wait for jobs to finish; stall? poll?
        sleep(10) # seconds 

        results = test_runs_repo.results_for_test_run(test_run.id)
        verbose_puts "Results:"
        verbose_puts serialize(results)

        results.each do |result|
          puts serialize(result)
        end

        puts COLOR.yellow "WIP: implementing"

      rescue Sequel::ValidationFailed, Sequel::ForeignKeyConstraintViolation,
             Inferno::Exceptions::RequiredInputsNotFound,
             Inferno::Exceptions::NotUserRunnableException => e
        $stderr.puts COLOR.red "Error: #{e.full_message}"
        # TODO: use Application Logger?
      rescue StandardError => e
        $stderr.puts COLOR.red "Error: #{e.full_message}"
      end

      def thor_hash_to_inputs_array(hash)
        hash.to_a.map{|pair| {name: pair[0], value: pair[1]}}
      end

      def serialize(entity)
        case entity.class.to_s
        when 'Array'
          entity.map{ |item| serialize(item) }
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

=begin
      def suppress_output
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

      def unindent_markdown(markdown)
        return nil if markdown.nil?

        natural_indent = markdown.lines.collect { |l| l.index(/[^ ]/) }.select { |l| !l.nil? && l.positive? }.min || 0
        markdown.lines.map { |l| l[natural_indent..-1] || "\n" }.join.lstrip
      end

      def print_requests(result)
        result.request_responses.map do |req_res|
          req_res.response_code.to_s + ' ' + req_res.request_method.upcase + ' ' + req_res.request_url
        end
      end

      # TODO better name
      def _run(runnable, test_session, inputs = {})
        test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
        test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
        inputs.each do |name, value|
          session_data_repo.save(test_session_id: test_session.id, name: name, value: value, type: 'text')
        end
        Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
      end
=end
    end
  end
end
