require_relative 'dsl/assertions'
require_relative 'dsl/fhir_client'
require_relative 'dsl/fhir_validation'
require_relative 'dsl/fhir_resource_validation'
require_relative 'dsl/http_client'
require_relative 'dsl/results'
require_relative 'dsl/runnable'
require_relative 'dsl/suite_endpoint'

module Inferno
  # The DSL for writing tests.
  module DSL
    INCLUDABLE_DSL_MODULES = [
      Assertions,
      FHIRClient,
      HTTPClient,
      Results,
      FHIRValidation,
      FHIRResourceValidation
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
