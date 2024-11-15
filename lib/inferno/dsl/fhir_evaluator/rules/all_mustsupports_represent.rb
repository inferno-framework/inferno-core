# frozen_string_literal: true

module FhirEvaluator
  module Rules
    class AllMustSupportPresent < HasExamples
      attr_accessor :config

      def check(context)
        @config = context.config
        unrepresented_elements = evaluate_elements(context)
        unrepresented_extensions = evaluate_extensions(context)

        if (unrepresented_elements.count + unrepresented_extensions.count).zero?
          result = EvaluationResult.new('All MustSupports represented', severity: 'success', rule: self)
        else
          message = 'Found Profiles with not all MustSupports represented: '
          result = EvaluationResult.new(message, rule: self)
          if unrepresented_elements.count.positive?
            result.message += "\n\tMustSupport elements not presented: "
            unrepresented_elements.each { |r| result.message += "\n\t\t#{r}" }
          end
          if unrepresented_extensions.count.positive?
            result.message += "\n\tMustSupport extensions not presented: "
            unrepresented_extensions.each { |r| result.message += "\n\t\t#{r}" }
          end
        end

        context.add_result result
      end

      def evaluate_elements(context)
        unrepresented_profiles = []
        context.ig.profiles.each do |structure_definition|
          ms_element_paths = get_mustsupport_elements(structure_definition)
          ms_element_paths.uniq!

          resource_elements = []
          context.data.each do |resource|
            ########################################################
            # Evaluate if a MS element is represented in examples with same profile URL with structure definition
            ########################################################
            if @config.Rule.AllMustSupportPresent.ExampleSelection.byMetaProfile
              versioned_url = "#{structure_definition.url}|#{structure_definition.version}"
              if Util.get_meta_profile(resource).include?(structure_definition.url) || Util.get_meta_profile(resource).include?(versioned_url)
                resource_elements += get_resource_paths(resource.to_hash)
              end
            end

            next unless @config.Rule.AllMustSupportPresent.ExampleSelection.byConformance

            if structure_definition.type == resource.resourceType && structure_definition.validates_resource?(resource)
              resource_elements += get_resource_paths(resource.to_hash)
            end
          end
          resource_elements.uniq!

          unrepresented_cnt = 0
          ms_element_paths.each do |path|
            unrepresented_cnt += 1 unless resource_elements.include?(path)
          end

          if unrepresented_cnt.positive?
            unrepresented_profiles << "#{structure_definition.name} (# represented MS elements: #{ms_element_paths.count - unrepresented_cnt} out of #{ms_element_paths.count})"
          end
        end
        unrepresented_profiles
      end

      def evaluate_extensions(context)
        unpresented_profiles = []
        context.ig.profiles.each do |structure_definition|
          ms_represent_cnt = 0
          resource_paths = []
          versioned_url = "#{structure_definition.url}|#{structure_definition.version}"

          context.data.each do |resource|
            unless Util.get_meta_profile(resource).include?(structure_definition.url) || Util.get_meta_profile(resource).include?(versioned_url)
              next
            end

            resource_paths += get_resource_paths_values(resource.to_hash['resourceType'],
                                                        resource.to_hash).select do |path|
              path[:path].include?('extension')
            end
          end

          resource_paths.uniq!

          extensions = get_mustsupport_extensions(structure_definition)
          extensions.each do |extension|
            value_exist_flg = false

            resource_paths.each do |path|
              resource_path = path[:path]
              ## Count if a path a Resource is extension, contains url, and urls match.
              if resource_path[extension[:path]] && resource_path['url'] && extension[:url] == path[:value]
                value_exist_flg = true
              end

              ## Count if a path of a Resource is extension, contains sliceName, and has (any) value.
              if resource_path[extension[:path]] && extension[:sliceName] && resource_path['value']
                value_exist_flg = true
              end

              ## Count if a path of a Resource is extension, contains slicing, and has (any) value.
              value_exist_flg = true if resource_path[extension[:path]] && extension[:slicing] && resource_path['value']
            end

            ms_represent_cnt += 1 if value_exist_flg
          end

          if extensions.count != ms_represent_cnt
            unpresented_profiles << "#{structure_definition.name} (# represented MS extensions: #{ms_represent_cnt} out of #{extensions.count})"
          end
        end
        unpresented_profiles
      end

      def get_resource_paths_values(resource_type, resource, current_path = '', result = [])
        if resource.is_a?(Array)
          resource.each_with_index do |element, index|
            get_resource_paths_values(resource_type, element, "#{current_path}[#{index}]", result)
          end
        elsif resource.is_a?(Hash)
          resource.each do |key, value|
            new_path = current_path.empty? ? key : "#{current_path}.#{key}"
            if value.is_a?(Array) || value.is_a?(Hash)
              get_resource_paths_values(resource_type, value, new_path, result)
            else
              result << { path: remove_fhir_datatype("#{resource_type}.#{new_path.gsub(/\[\d+\]/, '')}"), value: }
            end
          end
        else
          result << { path: remove_fhir_datatype("#{resource_type}.#{current_path.gsub(/\[\d+\]/, '')}"),
                      value: resource }
        end
        result
      end

      def remove_fhir_datatype(key)
        datatypes = ['CodeableConcept', 'String', 'Quantity', 'Boolean', 'Integer', 'Range', 'Ratio', 'SampleData',
                     'DateTime', 'Period', 'Time']
        datatypes.each { |dt| key = key.gsub(dt, '') }
        key
      end

      def get_resource_paths(hash, parent_key = '')
        result = []
        hash.each do |key, value|
          current_key = parent_key.empty? ? key : "#{parent_key}.#{key}"
          result << remove_fhir_datatype(current_key)
          result << get_resource_paths(value, current_key) if value.is_a?(Hash)
          result << get_resource_paths_list(value, current_key) if value.is_a?(Array)
        end
        result.flatten.uniq
      end

      def get_resource_paths_list(list, parent_key)
        result = []
        list.each do |value|
          # NOTE: that we re-use the same parent key here, we don't include the index
          result << remove_fhir_datatype(parent_key)
          result << get_resource_paths(value, parent_key) if value.is_a?(Hash)
          result << get_resource_paths_list(value, parent_key) if value.is_a?(Array)
        end
        result.flatten.uniq
      end

      def get_mustsupport_elements(structure_definition)
        mustsupport = []
        structure_definition.snapshot.element.each do |element|
          next unless element.mustSupport
          next if element.path['extension']

          ####################################
          # For now the evaluator only checks whether an element has value or not, by that an element with slice is evaluated the same way
          # Will come back if we decide to validate data for evaluating representation of MS elements.
          ####################################

          mustsupport << element.path.sub("#{element.path.split('.')[0]}.", '').gsub('[x]', '')
        end
        mustsupport
      end

      def get_mustsupport_extensions(structure_definition)
        mustsupport_extensions = []
        structure_definition.snapshot.element.each do |element|
          next unless element.mustSupport

          if element.base.path == 'DomainResource.extension'
            element.type.each do |type|
              type.profile&.each do |profile|
                mustsupport_extensions << { path: element.path, url: profile }
              end
            end
          end

          next unless element.base.path == 'Element.extension'

          mustsupport_extensions << { path: element.path, sliceName: element.sliceName } if element.sliceName
          element.slicing&.discriminator&.each do |dm|
            mustsupport_extensions << { path: element.path, slicing: dm.path }
          end
        end
        mustsupport_extensions.uniq
      end
    end
  end
end
