module Inferno
  module Feature
    class << self
      def requirements_enabled?
        ENV.fetch('ENABLE_REQUIREMENTS', 'false')&.casecmp?('true')
      end
    end
  end
end
