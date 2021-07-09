module Inferno
  # @api private
  class TestRunner
    attr_reader :test_session, :test_run

    def initialize(test_session:, test_run:)
      @test_session = test_session
      @test_run = test_run
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

    def start
      test_runs_repo.mark_as_running(test_run.id)

      run(test_run.runnable).tap do |results|
        test_runs_repo.mark_as_done(test_run.id) unless results.any?(&:waiting?)
      end
    end

    def run(runnable)
      if runnable < Entities::Test
        run_test(runnable)
      else
        run_group(runnable)
      end
    end

    def run_test(test)
      inputs = load_inputs(test)

      input_json_string = JSON.generate(inputs)
      test_instance = test.new(inputs: inputs, test_session_id: test_session.id)

      result = begin
        test_instance.load_named_requests
        test_instance.instance_eval(&test.block)
        'pass'
      rescue Exceptions::TestResultException => e
        test_instance.result_message = e.message
        e.result
      rescue StandardError => e
        Application['logger'].error(e.full_message)
        test_instance.result_message = "Error: #{e.message}"
        'error'
      end

      outputs = save_outputs(test_instance)
      output_json_string = JSON.generate(outputs)

      if result == 'wait'
        test_runs_repo.mark_as_waiting(test_run.id, test_instance.identifier, test_instance.wait_timeout)
      end

      [persist_result(
        {
          test_session_id: test_session.id,
          test_run_id: test_run.id,
          messages: test_instance.messages,
          requests: test_instance.requests,
          result: result,
          result_message: test_instance.result_message,
          input_json: input_json_string,
          output_json: output_json_string
        }.merge(test.reference_hash)
      )]
    end

    def run_group(group)
      results = []
      group.children.each do |child|
        result = run(child)
        results << result
        break if result.last.waiting?
      end

      results.flatten!

      results << persist_result(
        {
          test_session_id: test_session.id,
          test_run_id: test_run.id,
          result: roll_up_result(results)
        }.merge(group.reference_hash)
      )
    end

    def load_inputs(runnable)
      runnable.inputs.each_with_object({}) do |input, input_hash|
        name = input[:name]
        input_hash[name] = session_data_repo.load(test_session_id: test_session.id, name: name)
      end
    end

    def save_outputs(runnable_instance)
      outputs =
        runnable_instance.outputs.each_with_object({}) do |output_name, output_hash|
          output_hash[output_name] = runnable_instance.send(output_name)
        end

      outputs.each do |output_name, value|
        session_data_repo.save(
          test_session_id: test_session.id,
          name: output_name,
          value: value
        )
      end

      outputs
    end

    def persist_result(params)
      results_repo.create(params)
    end

    def roll_up_result(results)
      result_priority = Entities::Result::RESULT_OPTIONS
      unique_results = results.map(&:result).uniq
      result_priority.find do |result|
        unique_results.include? result
      end
    end
  end
end
