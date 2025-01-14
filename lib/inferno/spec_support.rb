module Inferno
  # @api private
  # This module provides constants so that unit tests in suite repositories can
  # load the factories defined in inferno.
  module SpecSupport
    FACTORY_BOT_SUPPORT_PATH = File.expand_path('../../spec/support/factory_bot', __dir__).freeze
    FACTORY_PATH = File.expand_path('../../spec/factories', __dir__).freeze
    REQUEST_HELPER_PATH = File.expand_path('../../spec/request_helper', __dir__).freeze
    RUNNABLE_HELPER_PATH = File.expand_path('../../spec/runnable_helper', __dir__).freeze
    TEST_KIT_SPEC = File.expand_path('../../spec/shared/test_kit_examples', __dir__).freeze

    def self.require_helpers
      require FACTORY_BOT_SUPPORT_PATH
      require RUNNABLE_HELPER_PATH
      require REQUEST_HELPER_PATH
      require TEST_KIT_SPEC
    end
  end
end
