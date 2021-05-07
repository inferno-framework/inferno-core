module Covid19VCI
  class FileDownload < Inferno::TestGroup
    id 'vci_file_download'
    title 'Download and validate a health card via file download'

    input :file_download_url

    test do
      id 'vci-file-01'
      title 'Health card can be downloaded'
      description 'The health card can be downloaded and is a valid JSON object'
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
        assert content_type.value.start_with?('application/smart-health-card'),
               "Content-Type header was '#{content_type.value}' instead of 'application/smart-health-card'"
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
      output :credential_strings

      run do
        skip_if request.status != 200, 'Health card not successfully downloaded'

        body = JSON.parse(response[:body])
        assert body.include?('verifiableCredential'),
               "Health card does not contain 'verifiableCredential' field"

        vc = body['verifiableCredential']

        assert vc.is_a?(Array), "'verifiableCredential' field must contain an Array"
        assert vc.length.positive?, "'verifiableCredential' field must contain at least one verifiable credential"

        output credential_strings: vc.join(',')

        pass "Received #{vc.length} verifiable #{'credential'.pluralize(vc.length)}"
      end
    end

    test do
      id 'vci-file-05'
      title 'Verifiable Credentials contain the correct headers'
      input :credential_strings

      run do
        skip_if credential_strings.blank?, 'No Verifiable Credentials received'
        credential_strings.split(',').each do |credential|
          header = HealthCards::JWS.from_jws(credential).header

          assert header['zip'] == 'DEF', "Expected 'zip' header to equal 'DEF', but found '#{header['zip']}'"
          assert header['alg'] == 'ES256', "Expected 'alg' header to equal 'ES256', but found '#{header['alg']}'"
          assert header['kid'].present?, "No 'kid' header was present"
        rescue StandardError => e
          assert false, "Error decoding credential: #{e.message}"
        end
      end
    end

    test do
      id 'vci-file-06'
      title 'Public key can be retrieved'
      input :credential_strings

      run do
        skip_if credential_strings.blank?, 'No Verifiable Credentials received'
        credential_strings.split(',').each do |credential|
          card = HealthCards::HealthCard.from_jws(credential)
          iss = card.issuer

          jws = HealthCards::JWS.from_jws(credential)

          assert iss.present?, 'Credential contains no `iss`'
          warning { assert iss.start_with?('https://'), "`iss` SHALL use the `https` scheme: #{iss}" }
          assert !iss.end_with?('/'), "`iss` SHALL NOT include a trailing `/`: #{iss}"

          key_set_url = "#{card.issuer}/.well-known/jwks.json"

          get(key_set_url)

          assert_response_status(200)
          assert_valid_json(response[:body])

          cors_header = request.response_header('Control-Allow-Origin')
          warning do
            assert cors_header.present?,
                   'No CORS header received. Issuers SHALL publish their public keys with CORS enabled'
            assert cors_header.value == '*',
                   "Expected CORS header value of `*`, but actual value was `#{cors_header.value}`"
          end

          key_set = JSON.parse(response[:body])

          public_key = key_set['keys'].find { |key| key['kid'] == jws.kid }

          assert public_key.present?, "Key set did not contain a key with a `kid` of #{jws.kid}"
          assert public_key['kty'] == 'EC', "Key had a `kty` value of `#{public_key['kty']}` instead of `EC`"
          assert public_key['use'] == 'sig', "Key had a `use` value of `#{public_key['use']}` instead of `sig`"
          assert public_key['alg'] == 'ES256', "Key had an `alg` value of `#{public_key['alg']}` instead of `ES256`"
          assert public_key['crv'] == 'P-256', "Key had a `crv` value of `#{public_key['crv']}` instead of `P-256`"
          # Shall have x and y equal to base64url-encoded values...
          assert !public_key.include?('d'), 'Key SHALL NOT have the private key parameter `d`'
        # Shall have kid equal to sha

        rescue StandardError => e
          assert false, "Error decoding credential: #{e.message}"
        end
      end
    end
  end
end
