module Inferno
  module DSL
    # This module contains the methods needed to configure and perform FHIRPath evaluations
    # on FHIR resources. The actual evaluation is typically performed by an external
    # FHIRPath evaluation service.
    #
    # Tests can leverage the evaluation functionality by  calling `evaluate_fhirpath` to retrieve
    # results of FHIRPath expressions.
    #
    # @example
    #
    #   fhirpath_evaluator url: 'http://example.com/fhirpath'
    #
    #   fhirpath_evaluator name: :custom, url: 'http://example.com/custom-fhirpath'
    #
    #   results = evaluate_fhirpath(patient_resource, 'Patient.name.given', :custom)
    #
    # results will be an array representing the result of evaluating the given
    # expression against the given root element.  Each "result" in the returned
    # array will be in the form `{ "type": "[FHIR datatype name]", "element": [JSON representation of element] }`.
    #
    # @note You can define multiple FHIRPath evaluators and use their names to choose the correct
    #   one when performing the evaluation.

    module FhirpathEvaluation
      def self.included(klass)
        klass.extend ClassMethods
      end

      # Evaluates a fhirpath expression for a given FHIR resource
      #
      # @param resource [FHIR::Model] the root FHIR resource to use when evaluating the fhirpath expression.
      # @param path [String] The FHIRPath expression to evaluate.
      # @param fhirpath_evaluator [Symbol] the name of the evaluator to use.
      # @return [Array] An array representing the result of evaluating the given expression against
      #   the given root resource.
      def evaluate_fhirpath(resource:, path:, fhirpath_evaluator: :default)
        find_fhirpath_evaluator(fhirpath_evaluator).evaluate_fhirpath(resource, path, self)
      end

      def find_fhirpath_evaluator(evaluator_name)
        self.class.find_fhirpath_evaluator(evaluator_name)
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
        # @return [Array] An array representing the result of evaluating the given expression against
        #   the given root resource. Each "result" in the returned array will be in the form
        #   `{ "type": "[FHIR datatype name]", "element": [JSON representation of element] }`.
        def evaluate_fhirpath(fhir_resource, fhirpath_expression, runnable)
          begin
            response = call_fhirpath_service(fhir_resource, fhirpath_expression)
          rescue StandardError => e
            # This could be a complete failure to connect (fhirpath service isn't running)
            # or a timeout (fhirpath service took too long to respond).
            runnable.add_message('error', e.message)
            raise Inferno::Exceptions::ErrorInFhirpathException, "Unable to connect to FHIRPath service at #{url}."
          end
          return JSON.parse(response.body) if response.status.to_s.start_with? '2'

          runnable.add_message('error', "FHIRPath service Response: HTTP #{response.status}\n#{response.body}")
          raise Inferno::Exceptions::ErrorInFhirpathException,
                'FHIRPath service call failed. Review Messages tab for more information.'
        rescue JSON::ParserError
          runnable.add_message('error', "Invalid FHIRPath service response format:\n#{response.body}")
          raise Inferno::Exceptions::ErrorInFhirpathException,
                'Error occurred in the FHIRPath service. Review Messages tab for more information.'
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
      end

      module ClassMethods
        # @private
        def fhirpath_evaluators
          @fhirpath_evaluators ||= {}
        end

        # Find a particular fhirpath evaluator. Looks through a runnable's parents up to
        # the suite to find an evaluator with a particular name
        def find_fhirpath_evaluator(evaluator_name)
          evaluator = fhirpath_evaluators[evaluator_name] || parent&.find_fhirpath_evaluator(evaluator_name)

          raise Inferno::Exceptions::FhirpathNotFoundException, evaluator_name if evaluator.nil?

          evaluator
        end

        # Define a fhirpath evaluator
        # @example
        #   fhirpath_evaluator url: 'http://example.com/fhirpath'
        #
        #   fhirpath_evaluator name: :custom, url: 'http://example.com/custom-fhirpath'
        #
        # @param name [Symbol] the name of the fhirpath evaluator, only needed if you are
        #   using multiple evaluators
        # @param url [String] the url of the fhirpath service
        def fhirpath_evaluator(name: :default, url: nil)
          fhirpath_evaluators[name] = Inferno::DSL::FhirpathEvaluation::Evaluator.new(url)
        end
      end
    end
  end
end
