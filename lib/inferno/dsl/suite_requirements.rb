require_relative 'requirement_set'

module Inferno
  module DSL
    module SuiteRequirements
      def requirement_sets(*sets)
        @requirement_sets = sets.map { |set| RequirementSet.new(**set) } if sets.present?

        @requirement_sets || []
      end
    end
  end
end
