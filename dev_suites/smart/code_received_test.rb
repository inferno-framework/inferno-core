module SMART
  class CodeReceivedTest < Inferno::Test
    title 'OAuth server sends code parameter'
    description %(
      Code is a required querystring parameter on the redirect.
    )
    id :smart_code_received

    output :code
    uses_request :redirect

    run do
      code = request.query_parameters['code']
      output code: code

      assert code.present?, 'No `code` paramater received'

      error = request.query_parameters['error']

      pass_if error.blank?

      error_message = "Error returned from authorization server. code: '#{error}'"
      error_description = request.query_parameters['error_description']
      error_uri = request.query_parameters['error_uri']
      error_message += ", description: '#{error_description}'" if error_description.present?
      error_message += ", uri: #{error_uri}" if error_uri.present?

      assert false, error_message
    end
  end
end
