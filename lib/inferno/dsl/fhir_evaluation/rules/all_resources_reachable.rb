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
            # TODO: add some customizable configurations for this rule:
            # - whether it should be checked at all
            # - determine the base/root resource
            # - which types/resources to ignore
            # TODO: for the customizable configurations, use the config settings below:
            # config.Rule.AllResourcesReachable.CheckedAtAll: true/false
            # config.Rule.AllResourcesReachable.RunOnlyBaseResource: true/false
            # config.Rule.AllResourcesReachable.IgnoreType: - value
            # TODO: can come up with a "connectedness metric" to see how well-connected the data set is

            # every resource is either making a resolvable reference or is referenced
            @referenced_resources = Set.new
            @referencing_resources = Set.new
            @resource_type_ids, @resource_ids, references = Inferno::Utils::EvaluatorUtil.extract_ids_references(context.data)
            references.each do |id, refs|
              assess_reachability(id, refs)
            end

            island_resources = @resource_ids - @referenced_resources - @referencing_resources

            if island_resources.any?
              sorted_island_resources = Set.new(island_resources.to_a.sort)
              message = "Found resources that have no resolved references and are not referenced: #{
            sorted_island_resources.to_a.join(', ')}"
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
