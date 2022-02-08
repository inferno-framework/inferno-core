Dir.glob(File.join(__dir__, '*.rb')).each { |path| require_relative path.delete_prefix("#{__dir__}/") }

module ONCProgram
  class Suite < Inferno::TestSuite
    title '2015 Edition Cures Update -  Standardized API Testing'
    short_title 'ONC Standardized API'
    description <<~DESCRIPTION
      Insert Description of the g10 test kit here.
    DESCRIPTION

    group from: :standalone_patient_app_full_access
    group from: :standalone_patient_app_limited_access
    group from: :ehr_practitioner_app
    group from: :single_patient_api
    group from: :multi_patient_api
    group from: :additional_tests
  end
end
