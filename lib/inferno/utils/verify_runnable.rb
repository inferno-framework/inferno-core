require_relative '../exceptions'

module Inferno
  module Utils
    # @private
    module VerifyRunnable
      def verify_runnable(runnable, inputs, selected_suite_options)
        missing_inputs = runnable&.missing_inputs(inputs, selected_suite_options)
        user_runnable = runnable&.user_runnable?
        raise Inferno::Exceptions::RequiredInputsNotFound, missing_inputs if missing_inputs&.any?
        raise Inferno::Exceptions::NotUserRunnableException unless user_runnable
      end
    end
  end
end
