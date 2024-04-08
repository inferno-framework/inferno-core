Inferno::Application.boot(:validator) do
  init do
    use :suites

    # This process should only run once, to start one job per validator,
    # so skipping it on workers will start it only once from the "web" process
    next if Sidekiq.server?

    next if ENV['APP_ENV'] == 'test'

    Inferno::Repositories::TestSuites.new.all.each do |suite|
      suite.fhir_validators.each do |name, validators|
        validators.each_with_index do |validator, index|
          if validator.is_a? Inferno::DSL::FHIRResourceValidation::Validator
            Inferno::Jobs.perform(Inferno::Jobs::InvokeValidatorSession, suite.id, name.to_s, index)
          end
        end
      end
    end
  end
end
