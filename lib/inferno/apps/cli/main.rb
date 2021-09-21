require_relative 'console'
module Inferno
  module CLI
    class Main < Thor
      desc 'console', 'Start an interactive console session with Inferno'
      def console
        Console.new.run
      end
    end
  end
end
