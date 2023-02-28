require_relative 'console'
require_relative 'migration'
require_relative 'services'
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

      desc 'start', 'Start Inferno'
      def start
        if `gem list -i foreman`.chomp == 'false'
          puts "You must install foreman with 'gem install foreman' prior to running inferno."
        end

        system 'foreman start --env=/dev/null'
      end

      desc 'watch', 'Start Inferno and watch for file changes'
      def watch
        if `gem list -i foreman`.chomp == 'false'
          puts "You must install foreman with 'gem install foreman' prior to running inferno."
        end
        if `gem list -i rerun`.chomp == 'false'
          puts "You must install rerun with 'gem install rerun' prior to running inferno while watching for file changes."
        end

        system 'rerun "foreman start --env=/dev/null"'
      end

      desc 'suites', 'List available test suites'
      def suites
        Suites.new.run
      end

      desc 'services stop/start', 'Start or stop background services'
      subcommand 'services', Services

      desc 'suite SUBCOMMAND ...ARGS', 'Perform suite-based operations'
      subcommand 'suite', Suite
    end
  end
end
