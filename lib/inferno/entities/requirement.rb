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
        :conditionality
      ].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)

        self.requirement_set = id.split('@').first if requirement_set.blank? && id&.include?('@')
      end

      def expand_sub_requirements
        return [] if sub_requirements.blank?

        current_set = nil
        sub_requirements
          .split(',')
          .map(&:strip)
          .flat_map do |requirement_string|
            current_set, requirement_string = requirement_string.split('@') if requirement_string.include?('@')

            requirement_ids =
              if requirement_string.include? '-'
                start_id, end_id = requirement_string.split('-')
                (start_id..end_id).to_a
              else
                [requirement_string]
              end

            requirement_ids.map { |id| "#{current_set}@#{id}" }
          end
      end
    end
  end
end
