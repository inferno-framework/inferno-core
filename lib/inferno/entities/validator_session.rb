module Inferno
  module Entities
    class ValidatorSession < Entity
      ATTRIBUTES = [
        :id,
        :created_at,
        :updated_at,
        :validator_session_id,
        :test_suite_id,
        :validator_name,
        :suite_options,
        :validator_index
      ].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end
    end
  end
end
