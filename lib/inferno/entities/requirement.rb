require_relative 'attributes'
require_relative 'entity'

module Inferno
  module Entities
    # A `Requirement` represents the specific rule or behavior a runnable is testing.
    class Requirement < Entity
      ATTRIBUTES = [
        :id,
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
      end
    end
  end
end
