require_relative 'dsl/assertions'
require_relative 'dsl/auth_info'
require_relative 'dsl/fhir_client'
require_relative 'dsl/fhir_validation'
require_relative 'dsl/fhir_evaluation/evaluator'
require_relative 'dsl/fhir_resource_validation'
require_relative 'dsl/fhirpath_evaluation'
require_relative 'dsl/http_client'
require_relative 'dsl/must_support_assessment'
require_relative 'dsl/results'
require_relative 'dsl/runnable'
require_relative 'dsl/suite_endpoint'
require_relative 'dsl/messages'

module Inferno
  # The DSL for writing tests.
  module DSL
    INCLUDABLE_DSL_MODULES = [
      Assertions,
      FHIRClient,
      HTTPClient,
      Results,
      FHIRValidation,
      FHIREvaluation,
      FHIRResourceValidation,
      FhirpathEvaluation,
      Messages,
      MustSupportAssessment
    ].freeze

    EXTENDABLE_DSL_MODULES = [
      Runnable
    ].freeze

    def self.included(klass)
      INCLUDABLE_DSL_MODULES.each do |dsl_module|
        klass.include dsl_module
      end

      EXTENDABLE_DSL_MODULES.each do |dsl_module|
        klass.extend dsl_module
      end
    end
  end
end
