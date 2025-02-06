# frozen_string_literal: true

require_relative '../reference_extractor'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllSearchParametersHaveExamples < HasExamples
          def check(context)
            unless ENV.fetch('FHIRPATH_URL')
              message = 'FHIRPATH_URL is not found. Skipping rule AllSearchParametersHaveExamples.'
              result = EvaluationResult.new(message, severity: 'warning', rule: self)
              context.add_result result
              return
            end

            get_unused_resource_urls(context.ig.search_params) do |param|
              param_is_used?(param, context)
            end

            if unused_resource_urls.any?
              message = "Found SearchParameters with no searchable data: #{unused_resource_urls.join(', ')}"
              result = EvaluationResult.new(message, rule: self)
            elsif !context.ig.search_params.empty?
              message = 'All SearchParameters have examples'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            else
              message = 'IG contains no SearchParameters'
              result = EvaluationResult.new(message, severity: 'information', rule: self)
            end

            context.add_result result
          end

          def param_is_used?(param, context)
            # Assume that all params have an expression (fhirpath)
            # This is not guaranteed since the field is 0..1
            # but without it there's no other way to select a value
            unless param.expression
              # message = "SearchParameter #{param.url} has no expression and cannot be checked"
              # result = EvaluationResult.new(message)
              # context.add_result result

              return true # for now
            end

            used = false

            context.data.each do |resource|
              next unless param.base.include? resource.resourceType

              begin
                result = evaluate(param.expression, resource)
              rescue StandardError => e
                message = "SearchParameter #{param.url} failed to evaluate due to an error. " \
                          "Expression: #{param.expression}. #{e}"
                result = EvaluationResult.new(message)
                context.add_result result

                # don't bother evaluating it again
                used = true
                break
              end

              if result && !result.empty?
                used = true
                break
              end
            end
            used
          end

          def evaluate(expression, resource)
            fhirpath_url = ENV.fetch('FHIRPATH_URL')
            path = "#{fhirpath_url}/evaluate?path=#{expression}"

            response = Faraday.post(path, resource.to_json, 'Content-Type' => 'application/json')
            raise "External FHIRPath service failed: #{response.status}" unless response.status.to_s.start_with? '2'

            # return value of the service is something like:
            # [ { "type": "date", "element": "2022-02-22" } ]
            # or an empty array if the selector didn't return anything

            JSON.parse(response.body)
          rescue Faraday::Error => e
            raise "FHIRPath service not available - HTTP request failed: #{e.message}"
          end
        end
      end
    end
  end
end
