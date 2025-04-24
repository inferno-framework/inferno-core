module DevelopmentTestKit
  class ExternalTest1 < Inferno::Test
    id 'external_test1'

    input :external_test1_input
    output :external_test1_output

    fhir_client :external_test1 do
      url 'EXTERNAL_TEST1'
    end

    run { assert suite_helper == 'SUITE_HELPER' }
  end
end
