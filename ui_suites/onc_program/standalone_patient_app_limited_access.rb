Dir.glob(File.join(__dir__, 'standalone_patient_app_limited_access', '*.rb')).each { |path| require_relative path.delete_prefix("#{__dir__}/") }

module ONCProgram
  class StandalonePatientAppLimitedAccess < Inferno::TestGroup
    title 'Standalone Patient App - Limited Access'
    description <<~DESCRIPTION
      This scenario demonstrates the ability to perform a Patient Standalone
      Launch to a [SMART on FHIR](http://www.hl7.org/fhir/smart-app-launch/)
      confidential client with limited access granted to the app based on user input.
      The tester is expected to grant the application access to a subset of
      desired resource types, and to deny requests for "offline_access"
      refresh tokens.
    DESCRIPTION

    id :standalone_patient_app_limited_access

    group from: :standalone_restricted_launch
    group from: :access_verify_restricted
  end
end
