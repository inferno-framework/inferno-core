require_relative '../../utils/tls_tester'
require_relative '../../utils/tls_assertions'
module USCore
  class TLSTest < Inferno::Test
    include USCoreUtils::TLS_Assertions

    title 'FHIR server secured by transport layer security --test--'
    description <<~DESCRIPTION
      All exchange of production data should be secured with TLS/SSL v1.2. test
    DESCRIPTION

    disable_tls_tests = ENV.fetch('DISABLE_TLS_TESTS').downcase
    id :tls_test

    input :url

    run do
      # config.yml?
      omit 'Test has been omitted because TLS tests have been disabled by configuration.' if disable_tls_tests == 'true'
      tls_tester = USCoreUtils::TlsTester.new(uri: url)

      assert_tls_1_2 url
      assert_deny_previous_tls url
    end
  end
end
