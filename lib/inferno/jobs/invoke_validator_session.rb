module Inferno
  module Jobs
    class InvokeValidatorSession
      include Sidekiq::Worker

      def perform(suite_id, validator_name, validator_index, required_suite_options)
        suite = Inferno::Repositories::TestSuites.new.find suite_id
        validator = suite.fhir_validators[validator_name.to_sym][validator_index]
        response_body = validator.validate(FHIR::Patient.new, 'http://hl7.org/fhir/StructureDefinition/Patient')
        if response_body.start_with? '{'
          res = JSON.parse(response_body)
          session_id = res['sessionId']
          session_repo = Inferno::Repositories::ValidatorSessions.new
          session_repo.save(test_suite_id: suite_id, validator_session_id: session_id,
                                validator_name:, suite_options: required_suite_options)
          validator.session_id = session_id
        else
          Inferno::Application['logger'].error("InvokeValidatorSession - error from validator: #{response_body}")
        end
      end
    end
  end
end
