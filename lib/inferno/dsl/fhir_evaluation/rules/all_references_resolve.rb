# frozen_string_literal: true

require_relative '../reference_extractor'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllReferencesResolve < Rule
          def check(context)
            extractor = Inferno::DSL::FHIREvaluation::ReferenceExtractor.new
            resource_type_ids = extractor.extract_resource_type_ids(context.data)
            resource_ids = Set.new(resource_type_ids.values.flatten.uniq)
            reference_map = extractor.extract_references(context.data)

            unresolved_references = Hash.new { |reference, id| reference[id] = [] }

            reference_map.each do |resource_id, references|
              references.each do |reference|
                if reference[:type] == ''
                  unresolved_references[resource_id] << reference unless resource_ids.include?(reference[:id])
                elsif !resource_type_ids[reference[:type]].include?(reference[:id])
                  unresolved_references[resource_id] << reference
                end
              end
            end

            if unresolved_references.any?
              message = gen_reference_fail_message(unresolved_references)
              result = EvaluationResult.new(message, rule: self)
            else
              message = 'All references resolve'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            end

            context.add_result result
          end

          def gen_reference_fail_message(unresolved_references)
            result_message = unresolved_references.map do |resource_id, references|
              reference_detail = references.map do |reference|
                " \n\tpath: #{reference[:path]}, type: #{reference[:type]}, id: #{reference[:id]}"
              end.join(',')
              "\n Resource (id): #{resource_id} #{reference_detail}"
            end.join(',')

            "Found unresolved references: #{result_message}"
          end
        end
      end
    end
  end
end
