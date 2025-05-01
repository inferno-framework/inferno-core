# frozen_string_literal: true

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllExtensionsUsed < Rule
          def check(context)
            all_extensions = collect_profile_extensions(context.ig.profiles)
            unused_extensions = remove_found_resource_extensions(all_extensions, context.data)
            if unused_extensions.any? { |_profile, extensions| !extensions.empty? }
              message = get_fail_message(unused_extensions)
              result = EvaluationResult.new(message, rule: self)
            else
              message = 'All extensions specified in profiles are used in examples.'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            end

            context.add_result result
          end

          def collect_profile_extensions(profiles)
            extensions = Hash.new { |extension, profile| extension[profile] = Set.new }
            profiles.each do |profile|
              profile.each_element do |value, metadata|
                next unless metadata['type'] == 'ElementDefinition'

                path_end = value.id.split('.')[-1]
                next unless path_end.include?('extension')

                value.type.each do |element_definition|
                  element_definition.profile.each do |extension_url|
                    extensions[profile.url].add(extension_url)
                  end
                end
              end
            end
            extensions
          end

          # rubocop:disable Metrics/CyclomaticComplexity
          def remove_found_resource_extensions(extensions, examples)
            unused_extensions = extensions.dup
            examples.each do |resource|
              resource.each_element do |value, _metadata, path|
                path_elements = path.split('.')
                next unless path_elements.length > 1

                next unless path_elements[-2].include?('extension') && path_elements[-1] == 'url'

                profiles = resource&.meta&.profile || []
                update_unused_extensions(profiles, value, unused_extensions, extensions)
              end
            end
            unused_extensions
          end
          # rubocop:enable Metrics/CyclomaticComplexity

          def update_unused_extensions(profiles, value, unused_extensions, extensions)
            profiles.each do |profile|
              unused_extensions[profile].delete(value) if extensions.key?(profile)
            end
          end

          def get_fail_message(extensions)
            message = 'Found extensions specified in profiles, but NOT used in examples:'
            extensions.each do |profile, extension|
              message += "\n Profile: #{profile}, \n\tExtensions: #{extension.join(', ')}" unless extension.empty?
            end
            message
          end
        end
      end
    end
  end
end
