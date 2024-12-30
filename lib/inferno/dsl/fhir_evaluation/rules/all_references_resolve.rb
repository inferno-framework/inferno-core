# frozen_string_literal: true

require_relative '../../../utils/evaluator_util'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllReferencesResolve < Rule
          def check(context)
            # resource_type_ids is for quick look up when there is a reference type
            # resource_ids is for quick look up when there is no type (i.e. uuid used)
            resource_type_ids, resource_ids, references = Inferno::Utils::EvaluatorUtil.extract_ids_references(context.data)
            unresolved_references = Hash.new { |h, k| h[k] = [] }
            references.each do |k, v|
              v.each do |reference|
                # no type for the reference
                if reference[1] == ''
                  unresolved_references[k] << reference unless resource_ids.include?(reference[2])
                elsif !resource_type_ids[reference[1]].include?(reference[2])
                  unresolved_references[k] << reference
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
            "Found unresolved references: #{
                            unresolved_references.map do |k, v|
                              "\n Resource (id): #{k}  #{v.each_with_index.map do |val, _idx|
                                                           val.each_with_index.map do |value, index|
                                                             case index
                                                             when 0
                                                               " \n\tpath: #{value}"
                                                             when 1
                                                               " type: #{value}"
                                                             when 2
                                                               " id: #{value}"
                                                             end
                                                           end
                                                         end.join(',')}"
                            end.join(',')}"
          end
        end
      end
    end
  end
end
