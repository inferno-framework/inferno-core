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
              fileName: 'manually_entered_file.json',
              fileContent: FHIR::Patient.new.to_json,
              fileType: 'json'
            }
          ]
        }

        request_body[:cliContext][:txServer] = nil if disable_tx

        # puts request_body.to_json

        response = Faraday.new(
          url,
          request: { timeout: 600 }
        ).post('validate', request_body.to_json, content_type: 'application/json')

        if response.body.start_with? '{'
          res = JSON.parse(response.body)
          session_id = res['sessionId']
          puts session_id
          # TODO: put this session ID somewhere so we can look it up

        else
          puts response.body
          puts response.status
          # TODO: something went wrong. now what?
        end
      end
    end
  end
end
