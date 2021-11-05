module ONCProgram
  class BulkDataGroupExport < Inferno::TestGroup
    title 'Group Compartment Export Tests'
    description <<~DESCRIPTION
      Verify that system level export on the Bulk Data server follow the Bulk Data Access Implementation Guide
    DESCRIPTION

    id :bulk_data_group_export

    input :bulk_server_url, :bulk_access_token #, :bulk_lines_to_validate

    fhir_client :bulk_server do
      url :bulk_server_url
    end

    http_client :bulk_server do
      url :bulk_server_url
    end

    test do
      title 'Bulk Data Server is secured by transport layer security'
      description <<~DESCRIPTION
        [§170.315(g)(10) Test Procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services) requires that
        all exchanges described herein between a client and a server SHALL be secured using Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246).
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#security-considerations'

      run {
        assert_valid_http_uri(bulk_server_url)
      }
    end

    test do
      title 'Bulk Data Server declares support for Group export operation in CapabilityStatement'
      description <<~DESCRIPTION
        The Bulk Data Server SHALL declare support for Group/[id]/$export operation in its server CapabilityStatement
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/OperationDefinition-group-export.html'

      include BulkDataUtils

      run {
        check_capability_statement
      }
    end

    test do

      title 'Bulk Data Server rejects $export request without authorization'
      description <<~DESCRIPTION
        The FHIR server SHALL limit the data returned to only those FHIR resources for which the client is authorized.

        [FHIR R4 Security](http://build.fhir.org/security.html#AccessDenied) and
        [The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750#section-3.1)
        recommend using HTTP status code 401 for invalid token but also allow the actual result be controlled by policy and context.
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#bulk-data-kick-off-request'

      include BulkDataUtils

      run {
        skip 'Could not verify this functionality when bearer token is not set' unless bulk_access_token

        export_kick_off(false)
        assert_response_status(401)
      }
    end

    test do
      title 'Bulk Data Server returns "202 Accepted" and "Content-location" for $export operation'
      description <<~DESCRIPTION
        Response - Success

        * HTTP Status Code of 202 Accepted
        * Content-Location header with the absolute URL of an endpoint for subsequent status requests (polling location)
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#response---success'

      include BulkDataUtils
      output :polling_url

      run {
        export_kick_off
        assert_response_status(202)

        polling_url = response[:headers].find { |header| header.name == 'content-location' }.value
        assert !!polling_url, 'Export response header did not include "Content-Location"'
        
        output polling_url: polling_url
      }
    end

    test do
      title 'Bulk Data Server returns "202 Accepted" or "200 OK" for status check'
      description <<~DESCRIPTION
        Clients SHOULD follow an exponential backoff approach when polling for status. Servers SHOULD respond with

        * In-Progress Status: HTTP Status Code of 202 Accepted
        * Complete Status: HTTP status of 200 OK and Content-Type header of application/json

        The JSON object of Complete Status SHALL contain these required field:

        * transactionTime, request, requiresAccessToken, output, and error
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#bulk-data-status-request'

      include BulkDataUtils
      input :polling_url
      makes_request :status_check

      http_client :polling_location do
        url :polling_url
      end

      run {
        timeout = 180
        skip 'Server response did not have Content-Location in header' unless polling_url
        check_export_status(timeout)

        skip "Server took more than #{timeout} seconds to process the request." if response[:status] == 202
        assert response[:status] == 200, "Bad response code: expected 200, 202, but found #{response[:status]}."

        assert_valid_json(response[:body])
        response_body = JSON.parse(response[:body])

        ['transactionTime', 'request', 'requiresAccessToken', 'output', 'error'].each do |key|
          assert response_body.key?(key), "Complete Status response did not contain \"#{key}\" as required"
        end
      }
    end

    test do
      title 'Bulk Data Server returns output with type and url for status complete'
      description <<~DESCRIPTION
        The value of output field is an array of file items with one entry for each generated file.
        If no resources are returned from the kick-off request, the server SHOULD return an empty array.

        Each file item SHALL contain the following fields:

        * type - the FHIR resource type that is contained in the file.

        Each file SHALL contain resources of only one type, but a server MAY create more than one file for each resource type returned.

        * url - the path to the file. The format of the file SHOULD reflect that requested in the _outputFormat parameter of the initial kick-off request.
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#response---complete-status'

      uses_request :status_check

      run {
        output = JSON.parse(response[:body])['output']
        assert output.present?, 'Sever response did not have output data'

        output.each do |file|
          ['type', 'url'].each do |key|
            assert file.key?(key), "Output file did not contain \"#{key}\" as required"
          end
        end
      }
    end

    test do
      title 'Bulk Data Server returns requiresAccessToken with value true'
      description <<~DESCRIPTION
        Bulk Data Server SHALL restrict bulk data file access with access token
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#response---complete-status'

      uses_request :status_check

      run {
        assert response.present?, 'Bulk Data server response is empty'
        requires_access_token = JSON.parse(response[:body])['requiresAccessToken']
        assert requires_access_token.present? && requires_access_token.to_s.downcase == 'true', 'Bulk Data file server access SHALL require access token.'
      }
    end

    test do
      title 'Bulk Data Server returns "202 Accepted" for delete request'
      description <<~DESCRIPTION
        After a bulk data request has been started, a client MAY send a delete request to the URL provided in the Content-Location header to cancel the request.
        Bulk Data Server MUST support client's delete request and return HTTP Status Code of "202 Accepted"
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#bulk-data-delete-request'

      run {
        export_kick_off
        assert_response_status(202)
       
        polling_url = response[:headers].find { |header| header.name == 'content-location' }.value
        assert !!polling_url, 'Export response header did not include "Content-Location"'

        # Should we add delete support to http_client?

      }
    end
  end
end
