module Inferno
  module Jobs
    class InvokeValidatorSession
      include Sidekiq::Worker
      sidekiq_options queue: 'validator_sessions'

      def perform(suite_id, validator_name, validator_index)
        suite = Inferno::Repositories::TestSuites.new.find suite_id
        validator = suite.fhir_validators[validator_name.to_sym][validator_index]
        validator.warm_up(FHIR::Patient.new, 'http://hl7.org/fhir/StructureDefinition/Patient')
      end
    end
  end
end
