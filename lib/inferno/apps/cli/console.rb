module Inferno
  module CLI
    class Console
      def run
        require_relative '../../../inferno'

        Inferno::Application.finalize!
        Pry.start
      end
    end
  end
end
