require_relative '../ext/fhir_models'

module Inferno
  module DSL
    module FHIREvaluation
      class Evaluator
        # @private
        def initialize
          require 'dotenv'
          Dotenv.load

          require 'faraday'
          require 'fhir_models'

          require_relative 'fhir_evaluator/config'
          require_relative 'fhir_evaluator/version'
          require_relative 'fhir_evaluator/evaluator'
          require_relative 'fhir_evaluator/ig'
          require_relative 'fhir_evaluator/rule'
          require_relative 'fhir_evaluator/evaluation_context'
          require_relative 'fhir_evaluator/evaluation_result'
          require_relative 'fhir_evaluator/data_summary'
          require_relative 'fhir_evaluator/dataset'

          Dir.glob(File.join(__dir__, 'fhir_evaluator', 'rules', '*.rb')).each do |file|
            require_relative file
          end

          require_relative 'fhir_evaluator/cli'
          FhirEvaluator::CLI.start
        end

        def evaluate
          puts 'Evaluate!'
        end
      end
    end
  end
end
