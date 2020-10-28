module Covid19VCI
  class Suite < Inferno::TestSuite
    id 'c19-vci'
    title 'COVID-19 Vaccine Credential'

    # group do
    #   id 'vci-fhir-download'
    # end

    group do
      id 'vci-file-download'
      title 'Download and validate a health card via file download'

      test do
        id 'vci-file-01'
        title 'Health card can be downloaded'
        description 'The health card can be downloaded and is a valid JSON object'
        input :file_download_url
        makes_request :vci_file_download

        run do
          get(file_download_url, name: :vci_file_download)

          assert_response_status(200)
          assert_valid_json(response[:body])
        end
      end

      test do
        id 'vci-file-02'
        title 'Response contains correct Content-Type of application/smart-health-card'
        uses_request :vci_file_download

        run do
          skip_if request.status != 200, 'Health card not successfully downloaded'

          content_type = request.response_header('Content-Type')

          assert content_type.present?, 'Response did not include a Content-Type header'
          assert content_type.value == 'application/smart-health-card',
                 "Content-Type header was '#{content_type}' instead of 'application/smart-health-card'"
        end
      end

      test do
        id 'vci-file-03'
        title 'Health card is provided as a file download with a .smart-health-card extension'
        uses_request :vci_file_download

        run do
          skip_if request.status != 200, 'Health card not successfully downloaded'

          pass_if request.url.ends_with?('.smart-health-card')

          content_disposition = request.response_header('Content-Disposition')
          assert content_disposition.present?,
                 "Url did not end with '.smart-health-card' and response did not include a Content-Disposition header"

          attachment_pattern = /\Aattachment;/
          assert content_disposition.value.match?(attachment_pattern),
                 "Url did not end with '.smart-health-card' and " \
                 "Content-Disposition header does not indicate file should be downloaded: '#{content_disposition}'"

          extension_pattern = /filename=".*\.smart-health-card"/
          assert content_disposition.value.match?(extension_pattern),
                 "Url did not end with '.smart-health-card' and Content-Disposition header does not indicate " \
                 "file should have a '.smart-health-card' extension: '#{content_disposition}'"
        end
      end

      test do
        id 'vci-file-04'
        title 'Response contains an array of Verifiable Credential strings'
        uses_request :vci_file_download

        run do
          skip_if request.status != 200, 'Health card not successfully downloaded'

          body = JSON.parse(response[:body])
          assert body.include?('verifiableCredential'),
                 "Health card does not contain 'verifiableCredential' field"

          vc = body['verifiableCredential']

          assert vc.is_a?(Array), "'verifiableCredential' field must contain an Array"
          assert vc.length.positive?, "'verifiableCredential' field must contain at least one verifiable credential"

          pass "Received #{vc.length} verifiable #{'credential'.pluralize(vc.length)}"
        end
      end
    end
  end
end
