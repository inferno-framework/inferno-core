# frozen_string_literal: true

require_relative '../reference_extractor'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllResourcesReachable < Rule
          attr_accessor :config, :referenced_resources, :referencing_resources, :resource_ids, :resource_type_ids

          def check(context)
            @config = context.config
            @referenced_resources = Set.new
            @referencing_resources = Set.new

            extractor = Inferno::DSL::FHIREvaluation::ReferenceExtractor.new
            @resource_type_ids = extractor.extract_resource_type_ids(context.data)
            @resource_ids = Set.new(resource_type_ids.values.flatten.uniq)
            reference_map = extractor.extract_references(context.data)

            reference_map.each do |resource_id, references|
              assess_reachability(resource_id, references)
            end

            island_resources = resource_ids - referenced_resources - referencing_resources
            island_resources.to_a.sort!

            if island_resources.any?
              message = "Found resources in examples have no resolved references and are not referenced: #{
                island_resources.join(', ')}"
              result = EvaluationResult.new(message, rule: self)
            else
              message = 'All resources in examples are reachable.'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            end

            context.add_result result
          end

          def assess_reachability(resource_id, references)
            makes_resolvable_reference = false
            references.each do |reference|
              type = reference[:type]
              referenced_id = reference[:id]

              if type == ''
                if resource_ids.include?(referenced_id)
                  makes_resolvable_reference = true
                  referenced_resources.add(referenced_id)
                end
              elsif resource_type_ids[type].include?(referenced_id)
                makes_resolvable_reference = true
                referenced_resources.add(referenced_id)
              end
            end
            referencing_resources.add(resource_id) if makes_resolvable_reference
          end
        end
      end
    end
  end
end
