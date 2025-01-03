# frozen_string_literal: true

require_relative '../../../utils/evaluator_util'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllResourcesReachable < Rule
          attr_accessor :config

          def check(context)
            @config = context.config

            # every resource is either making a resolvable reference or is referenced
            util = Inferno::Utils::EvaluatorUtil
            @referenced_resources = Set.new
            @referencing_resources = Set.new
            @resourcetype_ids, @resource_type_ids, @resource_ids, references = util.extract_ids_references(context.data)
            references.each do |id, refs|
              assess_reachability(id, refs)
            end

            island_resources = @resource_ids - @referenced_resources - @referencing_resources
            sorted_island_resources = []
            island_resources.each do |id|
              types = @resourcetype_ids.select { |_key, values| values.include?(id) }.keys
              sorted_island_resources << ("#{types[0]}/#{id}")
            end

            if sorted_island_resources.any?
              message = "Found resources that have no resolved references and are not referenced: #{
            sorted_island_resources.join(', ')}"
              result = EvaluationResult.new(message, rule: self)
            else
              message = 'All resources are reachable'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            end

            context.add_result result
          end

          def assess_reachability(id, references)
            makes_resolvable_reference = false
            references.each do |reference_data|
              # field = reference_data[0]
              type = reference_data[1]
              referenced_id = reference_data[2]

              # no type for the reference
              if type == ''
                if @resource_ids.include?(referenced_id)
                  makes_resolvable_reference = true
                  @referenced_resources.add(referenced_id)
                end
              elsif @resource_type_ids[type].include?(referenced_id)
                makes_resolvable_reference = true
                @referenced_resources.add(referenced_id)
              end
            end
            @referencing_resources.add(id) if makes_resolvable_reference
          end
        end
      end
    end
  end
end
