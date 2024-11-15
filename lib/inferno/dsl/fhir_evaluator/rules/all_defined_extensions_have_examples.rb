# frozen_string_literal: true

module FhirEvaluator
  module Rules
    class AllIGExtensionsHaveExamples < HasExamples
      def check(context)
        @used_resources = context.data.map { |e| extension_urls(e) }.flatten.uniq
        get_unused_resource_urls(context.ig.extensions) do |extension|
          next true if extension.context.any? do |ctx|
            # Skip extensions that are defined for definitional artifacts.
            # For example, US Core's uscdi-requirement extension is applied to
            #  the profiles and extensions of the IG, not data that conforms to the IG.
            # There may eventually be cases where SD/ED are data, so this may become configurable.
            ctx.expression == 'StructureDefinition' || ctx.expression == 'ElementDefinition'
          end

          versioned_url = "#{extension.url}|#{extension.version}"
          used_resources.include?(extension.url) || used_resources.include?(versioned_url)
        end

        if unused_resource_urls.any?
          message = "Found unused extensions defined in the IG: #{unused_resource_urls.join(', ')}"
          result = EvaluationResult.new(message, rule: self)
        else
          message = 'All defined extensions are represented in examples'
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
    end
  end
end
