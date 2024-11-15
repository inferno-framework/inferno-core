# frozen_string_literal: true

require_relative '../evaluator_util'

module FhirEvaluator
  module Rules
    class AllExtensionsUsed < Rule
      def check(context)
        # all_extensions and unused_extensions are hashes { profile_url: [extension_url,...]}
        all_extensions = collect_profile_extensions(context.ig.profiles)
        unused_extensions = remove_found_resource_extensions(all_extensions, context.data)

        if unused_extensions.any? { |_profile, extensions| !extensions.empty? }
          message = gen_extension_fail_message(unused_extensions)
          result = EvaluationResult.new(message, rule: self)
        else
          message = 'All extensions specified in profiles are represented in instances'
          result = EvaluationResult.new(message, severity: 'success', rule: self)
        end

        context.add_result result
      end

      def collect_profile_extensions(profiles)
        extensions = Hash.new { |h, k| h[k] = Set.new }
        profiles.each do |profile|
          profile.each_element do |value, metadata, _path|
            next unless metadata['type'] == 'ElementDefinition'

            path_end = value.id.split('.')[-1]
            next unless path_end.include?('extension')

            value.type.each do |t|
              t.profile.each do |p|
                extensions[profile.url].add(p)
              end
            end
          end
        end
        extensions
      end

      def remove_found_resource_extensions(extensions, examples)
        unused_extensions = extensions.dup
        examples.each do |resource|
          resource.each_element do |value, _metadata, path|
            path_elements = path.split('.')
            next unless path_elements.length > 1

            next unless path_elements[-2].include?('extension') && path_elements[-1] == 'url'

            profiles = Util.get_meta_profile(resource)
            profiles.each do |p|
              unused_extensions[p].delete(value) if extensions.key?(p)
            end
          end
        end
        unused_extensions
      end

      def gen_extension_fail_message(extensions)
        "Found extensions specified in profiles, but not used in instances: #{
                            extensions.map do |k, v|
                              next if v.empty?

                              "\n Profile: #{k},  \n\tExtensions: #{v.join(', ')}"
                            end.compact.join(',')}"
      end
    end
  end
end
