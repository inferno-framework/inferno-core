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
        assert_response_ok(error_message: error_message)
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

    def validate_read_reply(resource_given, reply_handler = nil)
      class_name = resource_given.class.name.demodulize
      if resource_given.is_a? FHIR::Reference
        store_request('outgoing') do
          resource_given.read
        end
        id = resource_given.reference.split('/').last
      else
        id = resource_given&.id
        assert !id.nil?, "#{class_name} id not returned"
        fhir_read class_name, id
        assert_response_ok
        reply_handler&.call(resource)
      end
      assert !resource.nil?, "Expected #{class_name} resource to be present."
      assert resource.is_a?(resource_given.class), "Expected resource to be of type #{class_name}."
      assert resource.id.present? && resource_given.id == resource.id, "Expected resource to contain id: #{id}"
      resource
    end

    def validate_vread_reply(resource_given)
      class_name = resource_given.class.name.demodulize
      assert !resource_given.nil?, "No #{class_name} resources available from search."
      id = resource_given.try(:id)
      assert !id.nil?, "#{class_name} id not returned"
      version_id = resource_given.try(:meta).try(:versionId)
      assert !version_id.nil?, "#{class_name} version_id not returned"
      store_request('outgoing') do
        fhir_client.vread(class_name, id, version_id)
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

    def validate_history_reply(resource_given)
      class_name = resource_given.class.name.demodulize
      assert !resource_given.nil?, "No #{class_name} resources available from search."
      id = resource_given.try(:id)
      assert !id.nil?, "#{class_name} id not returned"
      store_request('outgoing') do
        fhir_client.resource_instance_history(class_name, id)
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

    def walk_resource(resource, path = nil, &block)
      resource.class::METADATA.each do |field_name, meta|
        local_name = meta.fetch :local_name, field_name
        values = [resource.instance_variable_get("@#{local_name}")].flatten.compact
        next if values.empty?
    
        values.each_with_index do |value, i|
          child_path = if path.nil?
                         field_name
                       elsif meta['max'] > 1
                         "#{path}.#{field_name}[#{i}]"
                       else
                         "#{path}.#{field_name}"
                       end
          yield value, meta, child_path
          walk_resource value, child_path, &block unless FHIR::PRIMITIVES.include? meta['type']
        end
      end
    end

    class InvalidReferenceResource < StandardError; end
    
    def validate_reference_resolutions(resource, resolved_references = Set.new, max_resolutions = 1_000_000)
      problems = []

      walk_resource(resource) do |value, meta, path|
        next if meta['type'] != 'Reference'
        next if value.reference.blank?
        next if resolved_references.include?(value.reference)
        break if resolved_references.length > max_resolutions

        if value.contained?

          # if reference_id is blank it is referring to itself, so we know it exists
          next if value.reference_id.blank?

          # otherwise check to make sure the base resource has the contained element
          valid_contained = resource.contained.any? { |contained_resource| contained_resource&.id == value.reference_id }
          problems << "#{path} has contained reference to id '#{value.reference_id}' that does not exist" unless valid_contained
          next
        end

        begin
          # Should potentially update valid? method in fhir_dstu2_models
          # to check for this type of thing
          # e.g. "patient/54520" is invalid (fhir_client resource_class method would expect "Patient/54520")
          if value.relative?
            begin
              value.resource_class
            rescue NameError
              problems << "#{path} has invalid resource type in reference: #{value.type}"
              next
            end
          end
          reference = value.reference
          reference_type = value.resource_type
          resolved_resource = value.read

          raise InvalidReferenceResource if resolved_resource&.resourceType != reference_type

          resolved_references.add(value.reference)
        rescue ClientException => e
          problems << "#{path} did not resolve: #{e}"
        rescue InvalidReferenceResource
          problems << "Expected #{reference} to refer to a #{reference_type} resource, but found a #{resolved_resource&.resourceType} resource."
        end
      end

      # Inferno.logger.info "Surpassed the maximum reference resolutions: #{max_resolutions}" if resolved_references.length > max_resolutions

      assert(problems.empty?, "\n* " + problems.join("\n* "))
    end

    # pattern, values, type
    def find_slice(resource, path_to_ary, discriminator)
      resolve_element_from_path(resource, path_to_ary) do |array_el|
        case discriminator[:type]
        when 'patternCodeableConcept'
          path_to_coding = discriminator[:path].present? ? [discriminator[:path], 'coding'].join('.') : 'coding'
          resolve_element_from_path(array_el, path_to_coding) do |coding|
            coding.code == discriminator[:code] && coding.system == discriminator[:system]
          end
        when 'patternIdentifier'
          resolve_element_from_path(array_el, discriminator[:path]) { |identifier| identifier.system == discriminator[:system] }
        when 'value'
          values_clone = discriminator[:values].deep_dup
          values_clone.each do |value_def|
            value_def[:path] = value_def[:path].split('.')
          end
          find_slice_by_values(array_el, values_clone)
        when 'type'
          case discriminator[:code]
          when 'Date'
            begin
              Date.parse(array_el)
            rescue ArgumentError
              false
            end
          when 'String'
            array_el.is_a? String
          else
            array_el.is_a? FHIR.const_get(discriminator[:code])
          end
        end
      end
    end

    def find_slice_by_values(element, values)
      unique_first_part = values.map { |value_def| value_def[:path].first }.uniq
      Array.wrap(element).find do |el|
        unique_first_part.all? do |part|
          values_matching = values.select { |value_def| value_def[:path].first == part }
          values_matching.each { |value_def| value_def[:path] = value_def[:path].drop(1) }
          resolve_element_from_path(el, part) do |el_found|
            all_matches = values_matching.select { |value_def| value_def[:path].empty? }.all? { |value_def| value_def[:value] == el_found }
            remaining_values = values_matching.reject { |value_def| value_def[:path].empty? }
            remaining_matches = remaining_values.present? ? find_slice_by_values(el_found, remaining_values) : true
            all_matches && remaining_matches
          end
        end
      end
    end
  end
end
