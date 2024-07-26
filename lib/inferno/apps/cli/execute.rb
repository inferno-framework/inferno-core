# frozen_string_literal: true

require 'pastel'
require_relative '../../../inferno'

module Inferno
  module CLI
    class Execute

      COLOR = Pastel.new

      include Import[
                test_sessions_repo: 'inferno.repositories.test_sessions',
                session_data_repo: 'inferno.repositories.session_data',
                test_runs_repo: 'inferno.repositories.test_runs'
              ]

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

=begin
      def handle(req, res)
        test_session = test_sessions_repo.find(req.params[:test_session_id])

        # if testsession.nil?
        if test_runs_repo.active_test_run_for_session?(test_session.id)
          halt 409, { error: 'Cannot run new test while another test run is in progress' }.to_json
        end

        verify_runnable(
          repo.build_entity(create_params(req.params)).runnable,
          req.params[:inputs],
          test_session.suite_options
        )

        test_run = repo.create(create_params(req.params).merge(status: 'queued'))

        res.body = serialize(test_run, suite_options: test_session.suite_options)

        persist_inputs(req.params, test_run)

        Jobs.perform(Jobs::ExecuteTestRun, test_run.id)
      rescue Sequel::ValidationFailed, Sequel::ForeignKeyConstraintViolation,
             Inferno::Exceptions::RequiredInputsNotFound,
             Inferno::Exceptions::NotUserRunnableException => e
        halt 422, { errors: e.message }.to_json
      rescue StandardError => e
        Application['logger'].error(e.full_message)
        halt 500, { errors: e.message }.to_json
      end
=end

      def run(options)
        puts ''
        puts '=========================================='
        puts " Testing #{options[:suite]} Suite"
        puts '=========================================='

        Inferno::Application.start(:suites)        

        suite = Inferno::Repositories::TestSuites.new.find(options[:suite])
        raise StandardError, "Suite #{options[:suite]} not found" if suite.nil?

        test_session = test_sessions_repo.create({test_suite_id: suite.id}) # TODO add suite options

        # skip active test run check since new test session is minted

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

        # TODO to job or not to job that is the question
        Jobs.perform(Jobs::ExecuteTestRun, test_run.id)

        # how to properly wait for jobs to finish; stall? poll?
        sleep(20) # seconds 

        results = test_runs_repo.results_for_test_run(test_run.id)
        #puts serialize(results)
        puts results
        puts results.class
        puts results.to_json

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
