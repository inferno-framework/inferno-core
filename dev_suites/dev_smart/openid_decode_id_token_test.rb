module SMART
  class OpenIDDecodeIDTokenTest < Inferno::Test
    id :smart_openid_decode_id_token
    title 'ID token can be decoded'
    description %(
        Verify that the ID token is a properly constructed JWT.
      )

    input :id_token
    output :id_token_payload_json, :id_token_header_json

    run do
      skip_if id_token.blank?

      begin
        payload, header =
          JWT.decode(
            id_token,
            nil,
            false
          )

        output id_token_payload_json: payload.to_json,
               id_token_header_json: header.to_json
      rescue StandardError => e
        assert false, "ID token is not a properly constructed JWT: #{e.message}"
      end
    end
  end
end
