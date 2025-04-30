# frozen_string_literal: true

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllDefinedExtensionsHaveExamples < Rule
          attr_accessor :used_extensions, :unused_extensions

          def check(context)
            @used_extensions = context.data.map { |e| extension_urls(e) }.flatten.uniq
            @unused_extensions = []

            get_unused_extensions(context.ig.extensions) do |extension|
              next true if extension.context.any? do |ctx|
                # Skip extensions that are defined for definitional artifacts.
                # For example, US Core's uscdi-requirement extension is applied to
                # the profiles and extensions of the IG, not data that conforms to the IG.
                # There may eventually be cases where SD/ED are data, so this may become configurable.
                ctx.expression == 'StructureDefinition' || ctx.expression == 'ElementDefinition'
              end

              versioned_url = "#{extension.url}|#{extension.version}"
              used_extensions.include?(extension.url) || used_extensions.include?(versioned_url)
            end

            if unused_extensions.any?
              message = "Found defined extensions in the IG without examples: \n\t #{unused_extensions.join(', ')}"
              result = EvaluationResult.new(message, rule: self)
            else
              message = 'All defined extensions in the IG have examples.'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            end

            context.add_result result
          end

          def extension_urls(resource)
            urls = []
            resource.each_element do |value, _metadata, path|
              path_elements = path.split('.')
              next unless path_elements.length > 1

              urls << value if path_elements[-2].include?('extension') && path_elements[-1] == 'url'
            end
            urls.uniq
          end

          def get_unused_extensions(extensions, &extension_filter)
            extensions.each do |extension|
              unused_extensions.push extension.url unless extension_filter.call(extension)
            end
          end
        end
      end
    end
  end
end
