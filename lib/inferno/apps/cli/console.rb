module Inferno
  module CLI
    class Console
      def run
        require_relative '../../../inferno'

        ENV['ASYNC_JOBS'] = 'false'
        ENV['INITIALIZE_VALIDATOR_SESSIONS'] = 'false'

        Inferno::Application.finalize!
        Pry.start
      end
    end
  end
end
