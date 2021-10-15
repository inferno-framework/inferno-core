require_relative '../../../lib/inferno/exceptions'

module USCoreUtils
  module TLS_Assertions
    include Inferno::Exceptions

    def disable_tls_instructions
      %(
        You may safely ignore this error if this environment does not secure
        content using TLS. If you are running a local copy of Inferno you
        can turn off TLS detection by changing setting the
        `disable_tls_tests` option to true in `config.yml`.
      )
    end

    def uri_not_https_details(uri)
      %(
        The following URI does not use the HTTPS protocol identifier:

        [#{uri}](#{uri})

        The HTTPS protocol identifier is required for TLS connections.

        HTTP/TLS is differentiated from HTTP by using the `https`
        protocol identifier in place of the `http` protocol identifier. An
        example URI specifying HTTP/TLS is:
        `https://www.example.org`

        [HTTP Over TLS](https://tools.ietf.org/html/rfc2818#section-2.4)


        In order to fix this error you must secure this endpoint with TLS 1.2
        and ensure that references to this URL point to the HTTPS protocol so
        that use of TLS is explicit.
      ) + disable_tls_instructions
    end

    def tls_socket_error_details(uri)
      %(
        The following URI did not accept socket connections over port 443:

        [#{uri}](#{uri})

        ```
        When HTTP/TLS is being run over a TCP/IP connection, the default port
        is 443.
        ```
        [HTTP Over TLS](https://tools.ietf.org/html/rfc2818#section-2.3)


        To fix this error ensure that this URI is protected by TLS.
      ) + disable_tls_instructions
    end

    def tls_unexpected_error_details(uri)
      %(
        An unexpected error occured when attempting to connect to the
        following URI using TLS.

        [#{uri}](#{uri})

        To fix this error ensure that this URI is protected by TLS.
      ) + disable_tls_instructions
    end

    def assert_tls_1_2(uri)
      tls_tester = TlsTester.new(uri: uri)

      # need to add details to assert
      assert uri.downcase.start_with?('https'), "URI is not HTTPS: #{uri}" # , uri_not_https_details(uri)
      begin
        passed, message, details = tls_tester.verify_ensure_tls_v1_2
        assert passed, message # , details
      rescue AssertionException => e
        raise_error AssertionException
      rescue SocketError => e
        assert false, "Unable to connect to #{uri}: #{e.message}" # , tls_socket_error_details(uri)
      rescue StandardError => e
        assert false,
               "Unable to connect to #{uri}: #{e.class.name}, #{e.message}" # ,
        # tls_unexpected_error_details(uri)
      end
    end

    def assert_deny_previous_tls(uri)
      tls_tester = TlsTester.new(uri: uri)

      begin
        passed, message, details = tls_tester.verify_deny_ssl_v3
        assert passed, message # , details

        passed, message, details = tls_tester.verify_deny_tls_v1_1
        assert passed, message # , details

        passed, message, details = tls_tester.verify_deny_tls_v1
        assert passed, message # , details
      rescue AssertionException => e
        raise_error AssertionException
      rescue SocketError => e
        assert false, "Unable to connect to #{uri}: #{e.message}" # , tls_socket_error_details(uri)
      rescue StandardError => e
        assert false,
               "Unable to connect to #{uri}: #{e.class.name}, #{e.message}" # ,
        # tls_unexpected_error_details(uri)
      end
    end
  end
end
