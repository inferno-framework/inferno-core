module Inferno
  module Jobs
    class InvokeValidatorSession
      include Sidekiq::Worker

      def perform(suite_id, validator_name, validator_index)
        suite = Inferno::Repositories::TestSuites.new.find suite_id
        validator = suite.fhir_validators[validator_name.to_sym][validator_index]

        response_body = validator.validate(FHIR::Patient.new, 'http://hl7.org/fhir/StructureDefinition/Patient')

        if response_body.start_with? '{'
          res = JSON.parse(response_body)
          session_id = res['sessionId']
          # TODO: (FI-2311) store this session ID so it can be referenced as needed
          validator.session_id = session_id
        else
          Inferno::Application['logger'].error("InvokeValidatorSession - error calling validator. #{response.inspect}")
        end
      end
    end
  end
end
