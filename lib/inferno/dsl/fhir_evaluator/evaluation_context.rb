module Inferno
  module DSL
    module FHIREvaluation
      # EvaluationContext is a wrapper class around the concepts needed to perform an evaluation:
      # - The IG used as the basis for evaluation
      # - The data being evaluated
      # - A summary/characterization of the data
      # - Evaluation results
      class EvaluationContext
        attr_reader :ig, :data, :results, :config

        def initialize(the_ig, data, config)
          @ig = the_ig
          @data = data
          @results = []
          @config = config
        end

        def add_result(result)
          results.push result
        end
      end
    end
  end
end
