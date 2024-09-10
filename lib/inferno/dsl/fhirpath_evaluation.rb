module Inferno
  module DSL
    # This module contains the methods needed to perform FHIRPath evaluations
    # on FHIR resources/elements. The actual evaluation is typically performed by an external
    # FHIRPath evaluation service.
    #
    # Tests can leverage the evaluation functionality by  calling `evaluate_fhirpath` to retrieve
    # results of FHIRPath expressions.
    #
    # @example
    #
    #   results = evaluate_fhirpath(resource: patient_resource, path: 'Patient.name.given')
    #
    # results will be an array representing the result of evaluating the given
    # expression against the given root element.  Each "result" in the returned
    # array will be in the form
    # `{ "type": "[FHIR datatype of the result]", "element": "[result value of the FHIRPath expression]" }`.
    # @note the `element` field can either be a primitive value (string, boolean, etc.) or a FHIR::Model.
    module FhirpathEvaluation
      def self.included(klass)
        klass.extend ClassMethods
      end

      # Evaluates a fhirpath expression for a given FHIR resource
      #
      # @param resource [FHIR::Model] the root FHIR resource to use when evaluating the fhirpath expression.
      # @param path [String] The FHIRPath expression to evaluate.
      # @param url [String] the url of the fhirpath service to use.
      # @return [Array<Hash>] An array of hashes representing the result of evaluating the given expression against
      #   the given root resource.
      def evaluate_fhirpath(resource:, path:, url: nil)
        self.class.evaluator(url).evaluate_fhirpath(resource, path, self)
      end

      class Evaluator
        # @private
        def initialize(url = nil)
          url(url)
        end

        # @private
        def default_fhirpath_url
          ENV.fetch('FHIRPATH_URL')
        end

        # Set/Get the url of the fhirpath service
        #
        # @param fhirpath_url [String]
        # @return [String]
        def url(fhirpath_url = nil)
          @url ||= fhirpath_url || default_fhirpath_url
        end

        # Evaluates a fhirpath expression for a given FHIR resource
        #
        # @param fhir_resource [FHIR::Model] the root FHIR resource to use when evaluating the fhirpath expression.
        # @param fhirpath_expression [String] The FHIRPath expression to evaluate.
        # @param runnable [Inferno::Test] to add any error message that occurs.
        # @return [Array<Hash>] An array hashes representing the result of evaluating the given expression against
        #   the given root resource. Each "result" in the returned array will be in the form
        #   `{ "type": "[FHIR datatype of the result]", "element": "[result value of the FHIRPath expression]" }`.
        # @note the `element` field can either be a primitive value (string, boolean, etc.) or a FHIR::Model.
        def evaluate_fhirpath(fhir_resource, fhirpath_expression, runnable)
          begin
            response = call_fhirpath_service(fhir_resource, fhirpath_expression)
          rescue StandardError => e
            # This could be a complete failure to connect (fhirpath service isn't running)
            # or a timeout (fhirpath service took too long to respond).
            runnable.add_message('error', e.message)
            raise Inferno::Exceptions::ErrorInFhirpathException, "Unable to connect to FHIRPath service at #{url}."
          end

          sanitized_body = remove_invalid_characters(response.body)
          return transform_fhirpath_results(JSON.parse(sanitized_body)) if response.status.to_s.start_with? '2'

          runnable.add_message('error', "FHIRPath service Response: HTTP #{response.status}\n#{sanitized_body}")
          raise Inferno::Exceptions::ErrorInFhirpathException,
                'FHIRPath service call failed. Review Messages tab for more information.'
        rescue JSON::ParserError
          runnable.add_message('error', "Invalid FHIRPath service response format:\n#{sanitized_body}")
          raise Inferno::Exceptions::ErrorInFhirpathException,
                'Error occurred in the FHIRPath service. Review Messages tab for more information.'
        end

        # @private
        def transform_fhirpath_results(fhirpath_results)
          fhirpath_results.each do |result|
            klass = FHIR.const_get(result['type'])
            result['element'] = klass.new(result['element'])
          rescue NameError
            next
          end
          fhirpath_results
        end

        def call_fhirpath_service(fhir_resource, fhirpath_expression)
          Faraday.new(
            url,
            request: { timeout: 600 }
          ).post(
            "evaluate?path=#{fhirpath_expression}",
            fhir_resource.to_json,
            content_type: 'application/json'
          )
        end

        # @private
        def remove_invalid_characters(string)
          string.gsub(/[^[:print:]\r\n]+/, '')
        end
      end

      module ClassMethods
        # @private
        def evaluator(url = nil)
          @evaluator ||= Inferno::DSL::FhirpathEvaluation::Evaluator.new(url)
        end
      end
    end
  end
end
