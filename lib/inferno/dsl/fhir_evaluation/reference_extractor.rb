module Inferno
  module DSL
    module FHIREvaluation
      class ReferenceExtractor
        attr_accessor :resource_type_ids, :references

        def extract_resource_type_ids(resources)
          @resource_type_ids = Hash.new { |type, id| type[id] = [] }

          resources.each do |resource|
            resource.each_element do |value, metadata, path|
              next unless metadata['type'] == 'id'
              next if path.include?('contained')

              type = metadata['path'].partition('.').first.downcase
              resource_type_ids[type] << value
            end
          end

          resource_type_ids
        end

        def extract_references(resources)
          @references = Hash.new { |reference, id| reference[id] = [] }

          resources.each do |resource|
            extract_references_from_resource(resource)
          end

          references
        end

        def extract_references_from_resource(resource)
          resource.each_element do |value, metadata, path|
            if metadata['type'] == 'Reference' && !value.reference.nil?
              if value.reference.start_with?('#')
                next
              elsif value.reference.include? '/'
                add_parsed_reference(resource, value, path)
              elsif value.reference.start_with? 'urn:uuid:'
                references[resource.id] << { path: path, type: '', id: value.reference[9..] }
              else
                references[resource.id] << { path: path, type: '', id: value.reference }
              end
            end
          end
        end

        def add_parsed_reference(resource, value, path)
          type = value.reference.split('/')[-2].downcase
          id = value.reference.split('/')[-1]
          references[resource.id] << if resource_type_ids.key?(type)
                                       { path: path, type: type, id: id }
                                     else
                                       { path: path, type: '', id: value.reference }
                                     end
        end
      end
    end
  end
end
