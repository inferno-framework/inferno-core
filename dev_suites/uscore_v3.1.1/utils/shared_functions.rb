module USCore
  module HelperFunctions
    def fetch_all_bundled_resources(bundle, client, reply_handler: nil)
      page_count = 1
      resources = []
      until bundle.nil? || page_count == 20
        resources += bundle&.entry&.map { |entry| entry&.resource }
        next_bundle_link = bundle&.link&.find { |link| link.relation == 'next' }&.url
        reply_handler&.call(response)

        break if next_bundle_link.blank?

        reply = client.raw_read_url(next_bundle_link)
        error_message = "Could not resolve next bundle. #{next_bundle_link}"
        assert_response_ok(reply, error_message)
        assert_valid_json(reply.body, error_message)

        bundle = client.parse_reply(FHIR::Bundle, client.default_format, reply)

        page_count += 1
      end
      resources
    end

    def resolve_element_from_path(element, path)
      el_as_array = Array.wrap(element)
      if path.empty?
        return nil if element.nil?

        return el_as_array.find { |el| yield(el) } if block_given?

        return el_as_array.first
      end

      path_ary = path.split('.')
      cur_path_part = path_ary.shift.to_sym
      return nil if el_as_array.none? { |el| el.send(cur_path_part).present? || el.send(cur_path_part) == false }

      el_as_array.each do |el|
        el_found = if block_given?
                     resolve_element_from_path(el.send(cur_path_part), path_ary.join('.')) { |value_found| yield(value_found) }
                   else
                     resolve_element_from_path(el.send(cur_path_part), path_ary.join('.'))
                   end
        return el_found if el_found.present? || el_found == false
      end

      nil
    end

    def resolve_path(elements, path)
      elements = Array.wrap(elements)
      return elements if path.blank?

      paths = path.split('.')

      elements.flat_map do |element|
        resolve_path(element&.send(paths.first), paths.drop(1).join('.'))
      end.compact
    end

    def save_delayed_sequence_references(resources, delayed_sequence_references, scratch)
      resources.each do |resource|
        delayed_sequence_references.each do |delayed_sequence_reference|
          reference_elements = resolve_path(resource, delayed_sequence_reference[:path])
          reference_elements.each do |reference|
            next if !(reference.is_a? FHIR::Reference) || reference.contained?

            resource_class = reference.resource_class.name.demodulize
            is_delayed = delayed_sequence_reference[:resources].include?(resource_class)
            if is_delayed
              scratch[:delayed_resource_references][resource_class] =
                [] if scratch[:delayed_resource_references][resource_class].nil?
              scratch[:delayed_resource_references][resource_class].push(reference.reference.split('/').last)
            end
          end
        end
      end
    end

    def validate_reply_entries(resources, search_params)
      resources.each do |resource|
        # This checks to see if the base resource conforms to the specification
        # It does not validate any profiles.
        # resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class)
        assert resource_validation_errors[:errors].empty?,
               "Invalid #{resource.resourceType}: #{resource_validation_errors[:errors].join("\n* ")}"

        search_params.each do |key, value|
          unescaped_value = value&.gsub('\\,', ',')
          validate_resource_item(resource, key.to_s, unescaped_value)
        end
      end
    end

    def get_value_for_search_param(element, include_system = false)
      search_value = case element
                     when FHIR::Period
                       if element.start.present?
                         'gt' + (DateTime.xmlschema(element.start) - 1).xmlschema
                       else
                         end_datetime = get_fhir_datetime_range(element.end)[:end]
                         'lt' + (end_datetime + 1).xmlschema
                       end
                     when FHIR::Reference
                       element.reference
                     when FHIR::CodeableConcept
                       if include_system
                         coding_with_code = resolve_element_from_path(element, 'coding') { |coding| coding.code.present? }
                         coding_with_code.present? ? "#{coding_with_code.system}|#{coding_with_code.code}" : nil
                       else
                         resolve_element_from_path(element, 'coding.code')
                       end
                     when FHIR::Identifier
                       if include_system
                         "#{element.system}|#{element.value}"
                       else
                         element.value
                       end
                     when FHIR::Coding
                       if include_system
                         "#{element.system}|#{element.code}"
                       else
                         element.code
                       end
                     when FHIR::HumanName
                       element.family || element.given&.first || element.text
                     when FHIR::Address
                       element.text || element.city || element.state || element.postalCode || element.country
                     else
                       element
                     end
      escaped_value = search_value&.gsub(',', '\\,')
      escaped_value
    end

    def validate_read_reply(resource_given, client, reply_handler = nil)
      class_name = resource_given.class.name.demodulize
      if resource_given.is_a? FHIR::Reference
        store_request('outgoing') do
          resource_given.read
        end
        id = resource_given.reference.split('/').last
      else
        id = resource_given&.id
        assert !id.nil?, "#{class_name} id not returned"
        fhir_read class_name, id, client: client
        assert_response_ok
        reply_handler&.call(resource)
      end
      assert !resource.nil?, "Expected #{class_name} resource to be present."
      assert resource.is_a?(resource_given.class), "Expected resource to be of type #{class_name}."
      assert resource.id.present? && resource_given.id == id, "Expected resource to contain id: #{id}"
      resource
    end

    def validate_vread_reply(resource_given, client)
      class_name = resource_given.class.name.demodulize
      assert !resource_given.nil?, "No #{class_name} resources available from search."
      id = resource_given.try(:id)
      assert !id.nil?, "#{class_name} id not returned"
      version_id = resource_given.try(:meta).try(:versionId)
      assert !version_id.nil?, "#{class_name} version_id not returned"
      store_request('outgoing') do
        fhir_client(client).vread(class_name, id, version_id)
      end
      assert_response_ok
      assert !resource.nil?, "Expected valid #{class_name} resource to be present"
      assert resource.is_a?(resource_given.class), "Expected resource to be valid #{class_name}"
    end

    def validate_sort_order(entries)
      relevant_entries = entries.reject { |entry| entry.request&.local_method == 'DELETE' }
      begin
        relevant_entries.map!(&:resource).map!(&:meta).compact
      rescue StandardError
        assert(false, 'Unable to find meta for resources returned by the bundle')
      end

      relevant_entries.each_cons(2) do |left, right|
        left_version, right_version =
          if left.versionId.present? && right.versionId.present?
            [left.versionId, right.versionId]
          elsif left.lastUpdated.present? && right.lastUpdated.present?
            [left.lastUpdated, right.lastUpdated]
          else
            raise AssertionException, 'Unable to determine if entries are in the correct order -- no meta.versionId or meta.lastUpdated'
          end

        assert (left_version > right_version), 'Result contains entries in the wrong order.'
      end
    end

    def validate_history_reply(resource_given, client)
      class_name = resource_given.class.name.demodulize
      assert !resource_given.nil?, "No #{class_name} resources available from search."
      id = resource_given.try(:id)
      assert !id.nil?, "#{class_name} id not returned"
      store_request('outgoing') do
        fhir_client(client).resource_instance_history(class_name, id)
      end
      assert_response_ok
      # assert_valid_bundle_entries
      assert resource.type == 'history'
      entries = resource.try(:entry)
      assert entries, 'No bundle entries returned'
      assert entries.try(:length).positive?, 'No resources of this type were returned'
      validate_sort_order entries
    end

    def resources_with_invalid_binding(binding_def, resources)
      path_source = resources
      resources.map do |resource|
        binding_def[:extensions]&.each do |url|
          path_source = path_source.map { |el| el.extension.select { |extension| extension.url == url } }.flatten
        end
        invalid_code_found = resolve_element_from_path(path_source, binding_def[:path]) do |el|
          case binding_def[:type]
          when 'CodeableConcept'
            if el.is_a? FHIR::CodeableConcept
              # If we're validating a valueset (AKA if we have a 'system' URL)
              # We want at least one of the codes to be in the valueset
              if binding_def[:system].present?
                el.coding.none? do |coding|
                  Terminology.validate_code(valueset_url: binding_def[:system],
                                            code: coding.code,
                                            system: coding.system)
                end
              # If we're validating a codesystem (AKA if there's no 'system' URL)
              # We want all of the codes to be in their respective systems
              else
                el.coding.any? do |coding|
                  !Terminology.validate_code(valueset_url: nil,
                                             code: coding.code,
                                             system: coding.system)
                end
              end
            else
              false
            end
          when 'Quantity', 'Coding'
            !Terminology.validate_code(valueset_url: binding_def[:system],
                                       code: el.code,
                                       system: el.system)
          when 'code'
            !Terminology.validate_code(valueset_url: binding_def[:system], code: el)
          else
            false
          end
        end

        { resource: resource, element: invalid_code_found } if invalid_code_found.present?
      end.compact
    end

    def test_resources_against_profile(resources=[], specified_profile, &block)
      validation_results = resources.map do |resource|
        validator_result = resource_is_valid?(resource: resource, profile_url: specified_profile)
        if block_given?
          error_messages = yield resource
          error_messages.each { |msg| add_message('error', msg) }
          validator_result && error_messages.empty?
        else
          validator_result
        end
      end
      assert(validation_results.all?, "Resource does not conform to the profile: #{specified_profile}")
    end
  end
end
