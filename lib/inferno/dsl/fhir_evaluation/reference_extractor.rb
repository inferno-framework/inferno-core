module Inferno
  module DSL
    module FHIREvaluation
      class ReferenceExtractor
        def extract_resource_path_ids(resources)
          resource_path_ids = Hash.new { |resource_path, id| resource_path[id] = [] }

          resources.each do |resource|
            resource.each_element do |value, metadata, path|
              next unless metadata['type'] == 'id'
              next if path.include?('contained')

              first_path = metadata['path'].partition('.').first.downcase
              resource_path_ids[first_path] << value
            end
          end

          resource_path_ids
        end

        def extract_references(resources, resource_path_ids)
          @references = Hash.new { |reference, id| reference[id] = [] }
          @resource_path_ids = resource_path_ids

          resources.each do |resource|
            extract_references_from_resource(resource)
          end

          @references
        end

        def extract_references_from_resource(resource)
          resource.each_element do |value, metadata, path|
            if metadata['type'] == 'Reference' && !value.reference.nil?
              if value.reference.start_with?('#')
                # skip contained references (not separate resources)
                next
              elsif value.reference.include? '/'
                add_parsed_reference(resource, value, path)
              # if type is not specified in the reference, get type from the
              elsif path.include? 'Reference'
                add_reference_typed_path(resource, value, path)
              else
                # assumes this is a unique uuid
                reference = value.reference
                reference = reference[9..] if reference.start_with? 'urn:uuid:'
                @references[resource.id] << [path, '', reference]
              end
            end
          end
        end

        def add_parsed_reference(resource, value, path)
          type = value.reference.split('/')[-2].downcase
          id = value.reference.split('/')[-1]
          # assumes all profiles are represented
          @references[resource.id] << if @resource_path_ids.key?(type)
                                        [path, type, id]
                                      else
                                        # could include a warning here
                                        [path, '', value.reference]
                                      end
        end

        def add_reference_typed_path(resource, value, path)
          type = path.split('Reference', 2).downcase
          # assumes all profiles are represented
          @references[resource.id] << if @resource_path_ids.key?(type)
                                        [path, type, value.reference]
                                      else
                                        # could include a warning here
                                        [path, '', value.reference]
                                      end
        end
      end
    end
  end
end
