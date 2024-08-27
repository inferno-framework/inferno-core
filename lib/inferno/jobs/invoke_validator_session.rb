module Inferno
  module Jobs
    class InvokeValidatorSession
      include Sidekiq::Worker
      sidekiq_options queue: 'validator_sessions'

      def perform(suite_id, validator_name, validator_index)
        suite = Inferno::Repositories::TestSuites.new.find suite_id
        validator = suite.fhir_validators[validator_name.to_sym][validator_index]
        response_body = validator.validate(FHIR::Patient.new, 'http://hl7.org/fhir/StructureDefinition/Patient')
        res = JSON.parse(response_body)
        session_id = res['sessionId']
        session_repo = Inferno::Repositories::ValidatorSessions.new
        session_repo.save(test_suite_id: suite_id, validator_session_id: session_id,
                          validator_name:, suite_options: validator.requirements)
        validator.session_id = session_id
      rescue JSON::ParserError
        Inferno::Application['logger']
          .error("InvokeValidatorSession - error unexpected response format from validator: #{response_body}")
      end
    end
  end
end
