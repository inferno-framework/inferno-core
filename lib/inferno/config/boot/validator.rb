Inferno::Application.boot(:validator) do
  init do
    use :suites

    # This process should only run once, 
    # so do not run this step on worker threads
    # next if Sidekiq.server?

    Inferno::Repositories::TestSuites.new.all.each do |suite|
      suite.fhir_validators.each do |name, validators|

        validators.each do |validator|
          if validator.is_a? Inferno::DSL::FHIRResourceValidation::Validator
            Inferno::Jobs.perform(Inferno::Jobs::InvokeValidatorSession, validator.url, validator.igs)
          end
        end
      end
    end
  end
end
