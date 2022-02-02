Dir.glob(File.join(__dir__, '*.rb')).each { |path| require_relative path.delete_prefix("#{__dir__}/") }

module ONCProgram
  class Suite < Inferno::TestSuite
    title '2015 Edition Cures Update -  Standardized API Testing'
    short_title 'ONC Standardized API'
    description <<~DESCRIPTION
                  (TODO: update language)
      #{'      '}
                  Inferno Program Edition is a streamlined testing tool for Health Level 7 (HL7®) Fast Healthcare Interoperability Resources (FHIR®) services seeking to meet the requirements of the Standardized API for Patient and Population Services criterion § 170.315(g)(10) in the 2015 Edition Cures Update.
      #{'      '}
                  Inferno behaves like an API consumer, making a series of HTTP requests that mimic a real world client to ensure that the API supports all required standards, including:
            #{'      '}
                  * FHIR Release 4.0.1
                  *  FHIR US Core Implementation Guide (IG) STU 3.1.1
                  *  SMART Application Launch Framework Implementation Guide Release 1.0.0
                  *  HL7 FHIR Bulk Data Access (Flat FHIR) (v1.0.0: STU 1)
            #{'      '}
                  Inferno is open source and freely available for use or adoption by the health IT community including EHR vendors, health app developers, and testing labs. It can be used as a testing tool for the EHR Certification program supported by the Office of the National Coordinator for Health IT (ONC).
            #{'      '}
                  To get started, enter the endpoint of the FHIR service. Inferno Program Edition is only intended to be used on test systems that do not contain PHI.#{' '}
      #{'      '}
                  Links?  Recommend walking through scenarios on the left?  etc?
            #{'      '}
            #{'      '}
    DESCRIPTION

    group from: :standalone_patient_app_full_access
    group from: :standalone_patient_app_limited_access
    group from: :ehr_practitioner_app
    group from: :single_patient_api
    group from: :multi_patient_api
    group from: :additional_tests
  end
end
