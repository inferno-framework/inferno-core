# frozen_string_literal: true

require_relative '../reference_extractor'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllReferencesResolve < Rule
          def check(context)
            extractor = Inferno::DSL::FHIREvaluation::ReferenceExtractor.new
            resource_path_ids = extractor.extract_resource_type_ids(context.data)
            resource_ids = Set.new(resource_path_ids.values.flatten.uniq)
            reference_map = extractor.extract_references(context.data)

            unresolved_references = Hash.new { |reference, id| reference[id] = [] }

            reference_map.each do |id, references|
              references.each do |reference|
                if reference[1] == ''
                  unresolved_references[id] << reference unless resource_ids.include?(reference[2])
                elsif !resource_path_ids[reference[1]].include?(reference[2])
                  unresolved_references[id] << reference
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
            result_message = unresolved_references.map do |id, reference|
              reference_details = reference.map do |reference_detail|
                reference_detail.each_with_index.map do |value, index|
                  case index
                  when 0
                    " \n\tpath: #{value}"
                  when 1
                    " type: #{value}"
                  when 2
                    " id: #{value}"
                  end
                end.join(',')
              end.join(',')

              "\n Resource (id): #{id} #{reference_details}"
            end.join(',')

            "Found unresolved references: #{result_message}"
          end
        end
      end
    end
  end
end
