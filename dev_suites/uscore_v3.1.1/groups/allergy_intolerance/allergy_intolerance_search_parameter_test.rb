module USCore
  class AllergyIntoleranceSearchParametersTest < Inferno::Test
    input :url

    def validate_resource_item(resource, property, value)
      case property

      when 'clinical-status'
        values_found = resolve_path(resource, 'clinicalStatus')
        coding_system = value.split('|').first.empty? ? nil : value.split('|').first
        coding_value = value.split('|').last
        match_found = values_found.any? do |codeable_concept|
          if value.include? '|'
            codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
          else
            codeable_concept.coding.any? { |coding| coding.code == value }
          end
        end
        assert match_found,
               "clinical-status in AllergyIntolerance/#{resource.id} (#{values_found}) does not match clinical-status requested (#{value})"

      when 'patient'
        values_found = resolve_path(resource, 'patient.reference')
        value = value.split('Patient/').last
        match_found = values_found.any? { |reference|
          [value, 'Patient/' + value, "#{url}/Patient/#{value}"].include? reference
        }
        assert match_found,
               "patient in AllergyIntolerance/#{resource.id} (#{values_found}) does not match patient requested (#{value})"

      end
    end

    title 'Resources returned should match search parameters'
    description 'Resources returned should match search parameters'

    id :allergy_intolerance_search_params_validation

    run do
      allergy_intolerance_resources = scratch[:resources_returned]
      search_params = scratch[:search_parameters_used]
      allergy_intolerance_resources.each do |resource|
        search_params.each do |key, value|
          unescaped_value = value&.gsub('\\,', ',')
          validate_resource_item(resource, key.to_s, unescaped_value)
        end
      end
    end
  end
end
