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
        test_instance.result_message = "Error: #{e.message}"
        'error'
      end

      runnable.outputs.each do |output|
        outputs[output] = test_instance.send(output)
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
      results = runnable.children.flat_map { |child| run(child, inputs, outputs) }

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
