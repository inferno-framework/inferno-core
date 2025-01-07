# frozen_string_literal: true

require_relative '../reference_extractor'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllResourcesReachable < Rule
          attr_accessor :config, :referenced_resources, :referencing_resources, :resource_ids, :resource_path_ids

          def check(context)
            @config = context.config
            @referenced_resources = Set.new
            @referencing_resources = Set.new

            extractor = Inferno::DSL::FHIREvaluation::ReferenceExtractor.new
            @resource_path_ids = extractor.extract_resource_path_ids(context.data)
            @resource_ids = Set.new(resource_path_ids.values.flatten.uniq)
            references = extractor.extract_references(context.data, resource_path_ids)

            references.each do |id, refs|
              assess_reachability(id, refs)
            end

            island_resources = resource_ids - referenced_resources - referencing_resources
            sorted_island_resources = Set.new(island_resources.to_a.sort)

            if sorted_island_resources.any?
              message = "Found resources that have no resolved references and are not referenced: #{
                sorted_island_resources.join(', ')}"
              result = EvaluationResult.new(message, rule: self)
            else
              message = 'All resources are reachable'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            end

            result
          end

          def assess_reachability(id, references)
            makes_resolvable_reference = false
            references.each do |reference_data|
              # field = reference_data[0]
              type = reference_data[1]
              referenced_id = reference_data[2]

              # no type for the reference
              if type == ''
                if resource_ids.include?(referenced_id)
                  makes_resolvable_reference = true
                  referenced_resources.add(referenced_id)
                end
              elsif resource_path_ids[type].include?(referenced_id)
                makes_resolvable_reference = true
                referenced_resources.add(referenced_id)
              end
            end
            referencing_resources.add(id) if makes_resolvable_reference
          end
        end
      end
    end
  end
end
