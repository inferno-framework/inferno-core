module ONCProgram
  class USCoreDataAbsentReason < Inferno::TestGroup
    title 'Missing Data Tests'
    description <<~DESCRIPTION
      The [US Core Missing Data
      Guidance](http://hl7.org/fhir/us/core/general-guidance.html#missing-data)
      gives instructions on how to represent various types of missing data.

      In the previous resource tests, each resource returned from the server
      was checked for the presence of missing data. These tests will pass if
      the specified method of representing missing data was observed in the
      earlier tests.
    DESCRIPTION

    id :us_core_data_absent_reason

    input :url, :token, :patient_ids

    test do
      title 'Server represents missing data with the DataAbsentReason Extension'
      description <<~DESCRIPTION
        For non-coded data elements, servers shall use the DataAbsentReason
        Extension to represent missing data in a required field
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/general-guidance.html#missing-data'

      run {}
    end

    test do
      title 'Server represents missing data with the DataAbsentReason CodeSystem'
      description <<~DESCRIPTION
        For coded data elements with example, preferred, or extensible
        binding strengths to ValueSets which do not include an appropriate
        "unknown" code, servers shall use the "unknown" code from the
        DataAbsentReason CodeSystem.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/general-guidance.html#missing-data'

      run {}
    end
  end
end
