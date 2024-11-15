module FhirEvaluator
  # EvaluationContext is a wrapper class around the concepts needed to perform an evaluation:
  # - The IG used as the basis for evaluation
  # - The data being evaluated
  # - A summary/characterization of the data
  # - Evaluation results
  class EvaluationContext
    attr_reader :ig, :data, :summary, :results, :config

    def initialize(the_ig, data, summary, config)
      @ig = the_ig
      @data = data
      @summary = summary
      @results = []
      @config = config
    end

    def add_result(result)
      results.push result
    end
  end
end
