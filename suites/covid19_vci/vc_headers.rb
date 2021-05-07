module Covid19VCI
  class VCHeaders < Inferno::Test
    title 'Verifiable Credentials contain the correct headers'
    input :credential_strings

    id :vc_headers

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
end
