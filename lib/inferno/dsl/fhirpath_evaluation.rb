require 'fhir_models'

module Inferno
    module DSL
        module FhirpathEvaluation

            # Evaluates a fhirpath expression for a given instance of a FHIR resource
            #
            # @param fhir_resource [FHIR] the instance of a FHIR resource to use when evaluating the fhirpath expression
            # @param fhirpath_expression [String] the expression to evaluate for the given FHIR resource instance
            def evaluate_fhirpath(fhir_resource, fhirpath_expression)
                FHIRPath.evaluate(fhir_resource, fhirpath_expression)
            end

        end
    end
end