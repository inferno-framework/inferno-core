module IPS
  class Suite < Inferno::TestSuite
    title 'International Patient Summary (IPS)'
    description 'International Patient Summary (IPS)'

    id 'ips'

    group do
      title 'FHIR API Tests'
      input :url

      fhir_client do
        url :url
      end

      group do
        title 'Perform Operations'

        group from: :ips_document_operation
        group from: :ips_summary_operation
      end

      group do
        title 'Read and Validate Resources'

        group from: :ips_allergy_intolerance
        group from: :ips_bundle
        group from: :ips_composition
        group from: :ips_condition
        group from: :ips_device
        group from: :ips_device_observer
        group from: :ips_device_use_statement
        group from: :ips_diagnostic_report
        group from: :ips_imaging_study
        group from: :ips_immunization
        group from: :ips_media_observation
        group from: :ips_medication
        group from: :ips_medication_statement
        group do
          title 'Observation Resources'
          group from: :ips_observation_alcohol_use
          group from: :ips_observation_pregnancy_status
          group from: :ips_observation_pregnancy_edd
          group from: :ips_observation_tobacco_use
          group from: :ips_observation_results
          group from: :ips_observation_results_laboratory
          group from: :ips_observation_results_pathology
          group from: :ips_observation_results_radiology
          group from: :ips_observation_pregnancy_outcome
        end
        group from: :ips_organization
        group from: :ips_patient
        group from: :ips_practitioner
        group from: :ips_practitioner_role
        group from: :ips_procedure
        group from: :ips_specimen
      end
    end

  end
end
