module Inferno
  module Feature
    class << self
      def requirements_enabled?
        ENV.fetch('ENABLE_REQUIREMENTS', 'false')&.casecmp?('true')
      end

      def use_validation_context_key?
        ENV.fetch('USE_VALIDATION_CONTEXT', 'false')&.casecmp?('true')
      end
    end
  end
end
