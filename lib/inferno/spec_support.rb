module Inferno
  # @api private
  # This module provides constants so that unit tests in suite repositories can
  # load the factories defined in inferno.
  module SpecSupport
    FACTORY_BOT_SUPPORT_PATH = File.expand_path('../../spec/support/factory_bot', __dir__).freeze
    FACTORY_PATH = File.expand_path('../../spec/factories', __dir__).freeze
  end
end
