require_relative '../../fhirpath_evaluation'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllSearchParametersHaveExamples < Rule
          include FhirpathEvaluation

          attr_accessor :unused_resource_urls

          def check(context)
            unless ENV['FHIRPATH_URL']
              message = 'FHIRPATH_URL is not found. Skipping rule AllSearchParametersHaveExamples.'
              result = EvaluationResult.new(message, severity: 'warning', rule: self)
              context.add_result result
              return
            end

            @unused_resource_urls = []
            search_params = context.ig.resources_by_type['SearchParameter']

            get_unused_resource_urls(search_params) do |param|
              param_is_used?(param, context)
            end

            if unused_resource_urls.any?
              message = "Found SearchParameters with no searchable data: \n\t#{unused_resource_urls.join(' ,')}"
              result = EvaluationResult.new(message, rule: self)
            elsif !search_params.empty?
              message = 'All SearchParameters have examples'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            else
              message = 'IG contains no SearchParameter'
              result = EvaluationResult.new(message, severity: 'information', rule: self)
            end

            context.add_result result
          end

          def get_unused_resource_urls(ig_data, &resource_filter)
            ig_data.each do |resource|
              unused_resource_urls.push resource.url unless resource_filter.call(resource)
            end
          end

          def param_is_used?(param, context)
            # Assume that all params have an expression (fhirpath)
            # This is not guaranteed since the field is 0..1
            # but without it there's no other way to select a value
            return true unless param.expression

            used_flg = false

            context.data.each do |resource|
              next unless param.base.include? resource.resourceType

              begin
                result = evaluate_fhirpath(resource: resource, path: param.expression)
              rescue StandardError => e
                message = "SearchParameter #{param.url} failed to evaluate due to an error. " \
                          "Expression: #{param.expression}. #{e}"
                result = EvaluationResult.new(message)
                context.add_result result

                used_flg = true
                break
              end

              if result.present?
                used_flg = true
                break
              end
            end
            used_flg
          end

        end
      end
    end
  end
end
