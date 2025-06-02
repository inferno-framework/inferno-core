require_relative 'requirement_set'

module Inferno
  module DSL
    module SuiteRequirements
      # Get/Set the sets of requirments tested by a suite.
      #
      # @param sets [Array<Inferno::DSL::RequirementSet>]
      # @return [Array<Inferno::DSL::RequirementSet>]
      #
      # @example
      #   class Suite < Inferno::TestSuite
      #     requirement_sets(
      #       {
      #         identifier: 'example-regulation-1',
      #         title: 'Example Regulation 1',
      #         actor: 'Provider' # Only include requirements for the 'Provider'
      #                           # actor
      #       },
      #       {
      #         identifier: 'example-ig-1',
      #         title: 'Example Implementation Guide 1',
      #         actor: 'Provider',
      #         requirements: '2, 4-5' # Only include these specific requirements
      #       },
      #       {
      #         identifier: 'example-ig-2',
      #         title: 'Example Implementation Guide 2',
      #         requirements: 'Referenced', # Only include requirements from this
      #                                     # set that are referenced by other
      #                                     # included requirements
      #         actor: 'Server',
      #         suite_options: {      # Only include these requirements if the ig
      #           ig_version: '3.0.0' # version 3.0.0 suite option is selected
      #         }
      #       }
      #     )
      #   end
      def requirement_sets(*sets)
        @requirement_sets = sets.map { |set| RequirementSet.new(**set) } if sets.present?

        @requirement_sets || []
      end
    end
  end
end
