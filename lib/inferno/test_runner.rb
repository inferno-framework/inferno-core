require_relative 'result_summarizer'
require_relative 'utils/markdown_formatter'

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

      test_instance =
        test.new(
          inputs:,
          test_session_id: test_session.id,
          scratch:,
          suite_options: test_session.suite_options_hash
        )

      result = evaluate_runnable_result(test, test_instance, inputs)

      outputs = save_outputs(test_instance)
      output_json_string = JSON.generate(outputs)

      if result == 'wait'
        test_runs_repo.mark_as_waiting(test_run.id, test_instance.identifier, test_instance.wait_timeout)
      end

      test_result = persist_result(
        {
          messages: test_instance.messages,
          requests: test_instance.requests,
          result:,
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

    def check_inputs(test, _test_instance, inputs)
      inputs.each do |key, value|
        optional = test.config.input_optional?(key)
        if value.nil? && !optional
          raise Exceptions::SkipException,
                "Input '#{test.config.input_name(key)}' is nil, skipping test."
        end
      end
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

      if group.children.empty?
        group_result = persist_result(group.reference_hash.merge(result: 'omit',
                                                                 result_message: 'No tests defined',
                                                                 input_json: JSON.generate(group_inputs_with_values),
                                                                 output_json: '[]'))
        update_parent_result(group.parent)
        return group_result
      end

      group_instance = group.new

      group.children(test_session.suite_options).each do |child|
        result = run(child, scratch)
        group_instance.results << result
        break if result.waiting?
      end

      result = evaluate_runnable_result(group, group_instance) || roll_up_result(group_instance.results)

      group_result = persist_result(group.reference_hash.merge(
                                      messages: group_instance.messages,
                                      result:,
                                      result_message: group_instance.result_message,
                                      input_json: JSON.generate(group_inputs_with_values)
                                    ))

      update_parent_result(group.parent)

      group_result
    end

    def update_parent_result(parent)
      return if parent.nil?

      children = parent.children(test_session.suite_options)
      child_results = results_repo.current_results_for_test_session_and_runnables(test_session.id, children)
      return unless need_to_update_parent_result?(children, child_results, &parent.block)

      parent_instance = parent.new
      parent_instance.results << child_results
      old_result = results_repo.current_result_for_test_session(test_session.id, parent.reference_hash)&.result
      new_result = evaluate_runnable_result(parent, parent_instance) || roll_up_result(child_results)

      if new_result != old_result
        persist_result(parent.reference_hash.merge(
                         result: new_result,
                         result_message: parent_instance.result_message,
                         messages: parent_instance.messages
                       ))

        update_parent_result(parent.parent)
      end

      new_result
    end

    def evaluate_runnable_result(runnable, runnable_instance, inputs = nil)
      return if !(runnable < Entities::Test) && !runnable.block

      if runnable < Entities::Test
        raise Exceptions::CancelException, 'Test cancelled by user' if test_run_is_cancelling

        check_inputs(runnable, runnable_instance, inputs)

        runnable_instance.load_named_requests
      end
      runnable_instance.instance_eval(&runnable.block)
      'pass'
    rescue Exceptions::TestResultException => e
      runnable_instance.result_message = format_markdown(e.message)
      e.result
    rescue StandardError => e
      Application['logger'].error(e.full_message)
      runnable_instance.result_message = format_markdown("Error: #{e.message}\n\n#{e.backtrace.first}")
      'error'
    end

    # Determines if the parent result needs to be updated based on the results of its children.
    #
    # The parent result needs to be updated if:
    # - No custom result block is provided and all required children have corresponding required results.
    # - A custom result block is provided and all children have corresponding results.
    def need_to_update_parent_result?(children, child_results, &)
      required_children = children.select(&:required?)
      required_results = child_results.select(&:required?)

      (!block_given? && required_children.length == required_results.length) ||
        (block_given? && children.length == child_results.length)
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
