require_relative 'console'
require_relative 'migration'
require_relative 'suite'
require_relative 'suites'

module Inferno
  module CLI
    class Main < Thor
      desc 'console', 'Start an interactive console session with Inferno'
      def console
        Console.new.run
      end

      desc 'migrate', 'Run database migrations'
      def migrate
        Migration.new.run
      end

      desc 'suites', 'List available test suites'
      def suites
        Suites.new.run
      end

      desc 'suite SUBCOMMAND ...ARGS', 'Perform suite-based operations'
      subcommand 'suite', Suite
    end
  end
end
