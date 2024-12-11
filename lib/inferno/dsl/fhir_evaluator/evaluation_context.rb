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

        # rubocop:disable Naming/MethodParameterName
        def initialize(ig, data, config)
          @ig = ig
          @data = data
          @results = []
          @config = config
        end
        # rubocop:enable Naming/MethodParameterName

        def add_result(result)
          results.push result
        end
      end
    end
  end
end
