module Inferno
  module DSL
    module FHIREvaluation
      # EvaluationContext is a wrapper class around the concepts needed to perform an evaluation:
      # - The IG used as the basis for evaluation
      # - The data being evaluated
      # - A summary/characterization of the data
      # - Evaluation results
      # - A Validator instance, configured to point to the given IG
      class EvaluationContext
        attr_reader :ig, :data, :results, :config, :validator

        def initialize(ig, data, config, validator) # rubocop:disable Naming/MethodParameterName
          @ig = ig
          @data = data
          @results = []
          @config = config
          @validator = validator
        end

        def add_result(result)
          results.push result
        end
      end
    end
  end
end
