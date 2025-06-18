require_relative 'attributes'
require_relative 'entity'

module Inferno
  module Entities
    # A `Requirement` represents the specific rule or behavior a runnable is testing.
    class Requirement < Entity
      ATTRIBUTES = [
        :id,
        :requirement_set,
        :url,
        :requirement,
        :conformance,
        :actor,
        :sub_requirements,
        :conditionality,
        :not_tested_reason,
        :not_tested_details
      ].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)

        return unless requirement_set.blank? && (id&.include?('@') || id&.include?('#'))

        self.requirement_set = id.split(/[@#]/).first
      end

      # Expand a comma-delimited list of requirement id references into an Array
      # of full requirement ids
      #
      # @param requirement_id_string [String] A comma-delimited list of
      #   requirement id references
      # @param default_set [String] The requirement set identifier which will be
      #   used if none is included in the `requirement_id_string`
      #
      # @example
      #   expand_requirement_ids('example-ig@1,3,5-7')
      #   # => ['example-ig@1','example-ig@3','example-ig@5','example-ig@6','example-ig@7']
      #   expand_requirement_ids('example-ig')
      #   # => []
      #   expand_requirement_ids('1,3,5-7', 'example-ig')
      #   # => ['example-ig@1','example-ig@3','example-ig@5','example-ig@6','example-ig@7']
      #   expand_requirement_ids('example-ig#actor1')
      #   # => [all requirements for actor1 from example-ig]
      def self.expand_requirement_ids(requirement_id_string, default_set = nil) # rubocop:disable Metrics/CyclomaticComplexity
        return [] if requirement_id_string.blank?

        current_set = default_set
        requirement_id_string
          .split(',')
          .map(&:strip)
          .flat_map do |requirement_string|
            if requirement_string.include? '@'
              current_set, requirement_string = requirement_string.split('@')
            elsif requirement_string.include? '#'
              current_set, actor = requirement_string.split('#')
            end

            requirement_ids =
              if actor.present?
                return Repositories::Requirements.new.requirements_for_actor(current_set, actor).map(&:id)
              elsif requirement_string.include? '-'
                start_id, end_id = requirement_string.split('-')
                if start_id.match?(/^\d+$/) && end_id.match?(/^\d+$/)
                  (start_id..end_id).to_a
                else
                  []
                end
              else
                [requirement_string]
              end

            requirement_ids.map { |id| "#{current_set}@#{id}" }
          end
      end

      def actor?(actor_to_check)
        actor.any? { |actor| actor.casecmp? actor_to_check }
      end

      def tested?
        not_tested_reason.blank?
      end
    end
  end
end
