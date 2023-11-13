module Inferno
  module Jobs
    class InvokeValidatorSession
      include Sidekiq::Worker

      def perform(url, igs, disable_tx = false, display_issues_are_warnings = true)
        request_body = {
          cliContext: {
            sv: '4.0.1',
            displayWarnings: display_issues_are_warnings,
            # txServer: nil,          # -tx n/a
            igs: igs || []
          },
          filesToValidate: [
            {
              fileName: 'session_starter.json',
              fileContent: FHIR::Patient.new.to_json,
              fileType: 'json'
            }
          ]
        }

        request_body[:cliContext][:txServer] = nil if disable_tx

        response = Faraday.new(
          url,
          request: { timeout: 600 }
        ).post('validate', request_body.to_json, content_type: 'application/json')

        if response.body.start_with? '{'
          res = JSON.parse(response.body)
          session_id = res['sessionId']
          # TODO: (FI-2311) store this session ID so it can be referenced as needed,
          # instead of iterating through all test suites to find where it goes
          Inferno::Repositories::TestSuites.new.all.each do |suite|
            suite.fhir_validators.each do |name, validators|
              validators.each do |validator|
                if validator.url == url and validator.igs == igs
                  validator.session_id = session_id
                end
              end
            end
          end
        else
          Inferno::Application['logger'].error("InvokeValidatorSession - error calling validator. #{response.inspect}")
        end
      end
    end
  end
end
