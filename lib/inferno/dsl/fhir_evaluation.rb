require_relative '../ext/fhir_models'

module Inferno
  module DSL
    # This module contains the methods needed to configure a validator to
    # perform validation of FHIR resources. The actual validation is performed
    # by an external FHIR validation service. Tests will typically rely on
    # `assert_valid_resource` for validation rather than directly calling
    # methods on a validator.
    #
    # @example
    #
    #   validator do
    #     url 'http://example.com/validator'
    #     exclude_message { |message| message.type == 'info' }
    #     perform_additional_validation do |resource, profile_url|
    #       if something_is_wrong
    #         { type: 'error', message: 'something is wrong' }
    #       else
    #         { type: 'info', message: 'everything is ok' }
    #       end
    #     end
    #   end
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
