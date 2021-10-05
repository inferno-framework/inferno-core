module USCore
  module HelperFunctions
    def fetch_all_bundled_resources(bundle, client, reply_handler: nil)
      page_count = 1
      resources = []
      until bundle.nil? || page_count == 20
        resources += bundle&.entry&.map { |entry| entry&.resource }
        next_bundle_link = bundle&.link&.find { |link| link.relation == 'next' }&.url
        reply_handler&.call(reply)

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
              scratch[:delayed_resource_references][resource_class] = [] if scratch[:delayed_resource_references][resource_class].nil?
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
        assert resource_validation_errors[:errors].empty?, "Invalid #{resource.resourceType}: #{resource_validation_errors[:errors].join("\n* ")}"

        search_params.each do |key, value|
          unescaped_value = value&.gsub('\\,', ',')
          validate_resource_item(resource, key.to_s, unescaped_value)
        end
      end
    end
  end
end
