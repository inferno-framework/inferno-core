module Util
  # General util methods
  def self.get_meta_profile(resource)
    resource&.meta&.profile || []
  end

  # reference resolution methods
  def self.extract_ids_references(resources)
    extractor = ReferenceExtractor.new
    extractor.extract_ids_references(resources)
  end

  class ReferenceExtractor
    def initialize
      @resource_type_ids = Hash.new { |h, k| h[k] = [] }
      @resource_ids = Set.new
      @references = Hash.new { |h, k| h[k] = [] }
    end

    def extract_ids_references(resources)
      resources.each do |resource|
        resource.each_element do |value, metadata, path|
          next unless metadata['type'] == 'id'
          next if path.include?('contained')

          type = metadata['path'].partition('.').first.downcase
          @resource_type_ids[type] << value
          @resource_ids.add(value)
        end
      end

      extract_references(resources)

      [@resource_type_ids, @resource_ids, @references]
    end

    def extract_references(resources)
      # resources.each do |resource|
      #   resource.each_element do |value, metadata, path|
      #     if metadata['type'] == 'Reference' && !value.reference.nil?
      #       if value.reference.start_with?('#')
      #         # skip contained references (not separate resources)
      #         next
      #       elsif value.reference.include? '/'
      #         add_parsed_reference(resource, value, path)
      #       # if type is not specified in the reference, get type from the
      #       elsif path.include? 'Reference'
      #         add_reference_typed_path(resource, value, path)
      #       else
      #         # assumes this is a unique uuid
      #         reference = value.reference
      #         reference = reference[9..] if reference.start_with? 'urn:uuid:'
      #         @references[resource.id] << [path, '', reference]
      #       end
      #     end
      #   end
      # end
    end

    def add_parsed_reference(resource, value, path)
      type = value.reference.split('/')[-2].downcase
      id = value.reference.split('/')[-1]
      # assumes all profiles are represented
      @references[resource.id] << if @resource_type_ids.key?(type)
                                    [path, type, id]
                                  else
                                    # could include a warning here
                                    [path, '', value.reference]
                                  end
    end

    def add_reference_typed_path(resource, value, path)
      type = path.split('Reference', 2).downcase
      # assumes all profiles are represented
      @references[resource.id] << if @resource_type_ids.key?(type)
                                    [path, type, value.reference]
                                  else
                                    # could include a warning here
                                    [path, '', value.reference]
                                  end
    end
  end
end
