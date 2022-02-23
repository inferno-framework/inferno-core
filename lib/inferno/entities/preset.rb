require_relative 'attributes'
require_relative 'entity'
require_relative 'has_runnable'

module Inferno
  module Entities
    # A `Preset` represents a set of input values for a runnable.
    class Preset < Entity
      ATTRIBUTES = [
        :id,
        :test_suite_id,
        :inputs,
        :title
      ].freeze

      include Inferno::Entities::Attributes
      include Inferno::Entities::HasRunnable

      def initialize(params)
        super(params, ATTRIBUTES)
      end
    end
  end
end
