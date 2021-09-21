module Inferno
  module CLI
    class Console
      def run
        Inferno::Application.finalize!
        Pry.start
      end
    end
  end
end
