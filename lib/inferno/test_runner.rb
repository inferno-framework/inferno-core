require_relative './result_summarizer'
require_relative './utils/markdown_formatter'

module Inferno
  # @private
  class TestRunner
    include Inferno::Utils::MarkdownFormatter
    attr_reader :test_session, :test_run, :resuming

    def initialize(test_session:, test_run:, resume: false)
      @test_session = test_session
      @test_run = test_run
      @resuming = resume
    end

    def run_results
      @run_results ||= {}
    end

    def results_repo
      @results_repo ||= Repositories::Results.new
    end

    def test_runs_repo
      @test_runs_repo ||= Repositories::TestRuns.new
    end

    def session_data_repo
      @session_data_repo ||= Repositories::SessionData.new
    end

    def test_run_is_cancelling
      # forces db refetch of the test run status in case it is being cancelled
      test_runs_repo.status_for_test_run(test_run.id) == 'cancelling'
    end

    def start
      test_runs_repo.mark_as_running(test_run.id) unless test_run.status == 'cancelling'

      run(test_run.runnable)

      test_runs_repo.mark_as_done(test_run.id) unless run_results.values.any?(&:waiting?)

      run_results.values
    end

    def run(runnable, scratch = {})
      if runnable < Entities::Test
        return existing_test_result(runnable) || run_test(runnable, scratch) if resuming

        run_test(runnable, scratch)
      else
        run_group(runnable, scratch)
      end
    end

    def existing_test_result(runnable)
      results_repo.result_for_test_run(runnable.reference_hash.merge(test_run_id: test_run.id))
    end

    def run_test(test, scratch)
      inputs = load_inputs(test)
      input_json_string = inputs_as_json(test, inputs)

      test_instance = test.new(inputs: inputs, test_session_id: test_session.id, scratch: scratch)

      result = begin
        raise Exceptions::CancelException, 'Test cancelled by user' if test_run_is_cancelling

        test_instance.load_named_requests
        test_instance.instance_eval(&test.block)
        'pass'
      rescue Exceptions::TestResultException => e
        test_instance.result_message = format_markdown(e.message)
        e.result
      rescue StandardError => e
        Application['logger'].error(e.full_message)
        test_instance.result_message = format_markdown("Error: #{e.message}\n\n#{e.backtrace.first}")
        'error'
      end

      outputs = save_outputs(test_instance)
      output_json_string = JSON.generate(outputs)

      if result == 'wait'
        test_runs_repo.mark_as_waiting(test_run.id, test_instance.identifier, test_instance.wait_timeout)
      end

      test_result = persist_result(
        {
          messages: test_instance.messages,
          requests: test_instance.requests,
          result: result,
          result_message: test_instance.result_message,
          input_json: input_json_string,
          output_json: output_json_string
        }.merge(test.reference_hash)
      )

      # If running a single test, update its parents' results. If running a
      # group or suite, #run_group handles updating the parents.
      return test_result if test_run.test_id.blank?

      update_parent_result(test.parent)

      test_result
    end

    def run_group(group, scratch)
      group_inputs_with_values = group.available_inputs.map do |_input_identifier, input|
        {
          name: input.name,
          label: input.title,
          description: input.description,
          value: session_data_repo.load(test_session_id: test_session.id, name: input.name, type: input.type),
          type: input.type
        }
      end

      results = []
      group.children(test_session.suite_options).each do |child|
        result = run(child, scratch)
        results << result
        break if results.last.waiting?
      end

      results.flatten!

      group_result = persist_result(group.reference_hash.merge(result: roll_up_result(results),
                                                               input_json: JSON.generate(group_inputs_with_values)))

      update_parent_result(group.parent)

      group_result
    end

    def update_parent_result(parent)
      return if parent.nil?

      children = parent.children(test_session.suite_options)
      child_results = results_repo.current_results_for_test_session_and_runnables(test_session.id, children)
      required_children = children.select(&:required?)
      required_results = child_results.select(&:required?)
      return if required_children.length != required_results.length

      old_result = results_repo.current_result_for_test_session(test_session.id, parent.reference_hash)&.result
      new_result = roll_up_result(child_results)

      if new_result != old_result
        persist_result(parent.reference_hash.merge(result: new_result))

        update_parent_result(parent.parent)
      end

      new_result
    end

    def load_inputs(runnable)
      runnable.inputs.each_with_object({}) do |input_identifier, input_hash|
        input_alias = runnable.config.input_name(input_identifier)
        input_type = runnable.config.input_type(input_identifier)
        input_hash[input_identifier] =
          session_data_repo.load(test_session_id: test_session.id, name: input_alias, type: input_type)
      end
    end

    def inputs_as_json(runnable, input_values)
      inputs_array = runnable.inputs.map do |input_identifier|
        {
          name: runnable.config.input_name(input_identifier),
          value: input_values[input_identifier],
          type: runnable.config.input_type(input_identifier)
        }
      end
      JSON.generate(inputs_array)
    end

    def save_outputs(runnable_instance)
      outputs =
        runnable_instance.outputs_to_persist.map do |output_identifier, value|
          output_name = runnable_instance.class.config.output_name(output_identifier)
          output_type = runnable_instance.class.config.output_type(output_identifier)
          {
            name: output_name,
            type: output_type,
            value: value.to_s
          }
        end

      outputs.compact!
      outputs.each do |output|
        session_data_repo.save(output.merge(test_session_id: test_session.id))
      end
    end

    def persist_result(params)
      result = results_repo.create(
        params.merge(test_run_id: test_run.id, test_session_id: test_session.id)
      )

      run_results[result.runnable.id] = result
    end

    def roll_up_result(results)
      ResultSummarizer.new(results).summarize
    end
  end
end
