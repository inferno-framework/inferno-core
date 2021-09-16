module SMART
  class TokenResponseHeadersTest < Inferno::Test
    title 'Response includes correct HTTP Cache-Control and Pragma headers'
    description %(
      The authorization servers response must include the HTTP Cache-Control
      response header field with a value of no-store, as well as the Pragma
      response header field with a value of no-cache.
    )
    id :smart_token_response_headers

    uses_request :token

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'

      cc_header = request.response_header('Cache-Control')&.value

      assert cc_header&.downcase&.include?('no-store'),
             'Token response must have `Cache-Control` header containing `no-store`.'

      pragma_header = request.response_header('Pragma')&.value

      assert pragma_header&.downcase&.include?('no-cache'),
             'Token response must have `Pragma` header containing `no-cache`.'
    end
  end
end
