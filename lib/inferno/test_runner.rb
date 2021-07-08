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

    def start(inputs = {}, outputs = {})
      test_runs_repo.mark_as_running(test_run.id)

      # TODO: persist inputs

      run(test_run.runnable, inputs, outputs).tap do |results|
        test_runs_repo.mark_as_done(test_run.id) unless results.any?(&:waiting?)
      end
    end

    def run(runnable, inputs = {}, outputs = {})
      if runnable < Entities::Test
        run_test(runnable, inputs, outputs)
      else
        run_group(runnable, inputs, outputs)
      end
    end

    def run_test(runnable, inputs = {}, outputs = {})
      test_instance = runnable.new(inputs: inputs.merge(outputs), test_session_id: test_session.id)

      result = begin
        inputs.merge(outputs).each do |key, value|
          test_instance.instance_variable_set("@#{key}", value)
        end
        test_instance.load_named_requests
        test_instance.instance_eval(&runnable.block)
        'pass'
      rescue Exceptions::TestResultException => e
        test_instance.result_message = e.message
        e.result
      rescue StandardError => e
        Application['logger'].error(e.full_message)
        test_instance.result_message = "Error: #{e.message}"
        'error'
      end

      runnable.outputs.each do |output|
        # TODO: persist outputs

        outputs[output] = test_instance.send(output)
      end

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
          result_message: test_instance.result_message
        }.merge(runnable.reference_hash)
      )]
    end

    def run_group(runnable, inputs = {}, outputs = {})
      results = []
      runnable.children.each do |child|
        result = run(child, inputs, outputs)
        results << result
        break if result.last.waiting?
      end

      results.flatten!

      results << persist_result(
        {
          test_session_id: test_session.id,
          test_run_id: test_run.id,
          result: roll_up_result(results)
        }.merge(runnable.reference_hash)
      )
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
