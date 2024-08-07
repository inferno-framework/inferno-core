require_relative 'console'
require_relative 'migration'
require_relative 'services'
require_relative 'suite'
require_relative 'suites'
require_relative 'new'
require_relative '../../version'

module Inferno
  module CLI
    class Main < Thor
      desc 'console', 'Start an interactive console session with Inferno'
      def console
        Migration.new.run(Logger::INFO)
        Console.new.run
      end

      desc 'migrate', 'Run database migrations'
      def migrate
        Migration.new.run
      end

      desc 'start', 'Start Inferno'
      option :watch,
             default: false,
             type: :boolean,
             desc: 'Automatically restart Inferno when a file is changed.'
      def start
        Migration.new.run(Logger::INFO)

        without_bundler do
          command = 'foreman start --env=/dev/null'

          if `gem list -i foreman`.chomp == 'false'
            puts "You must install foreman with 'gem install foreman' prior to running Inferno."
          end

          if options[:watch]
            if `gem list -i rerun`.chomp == 'false'
              puts "You must install 'rerun' with 'gem install rerun' to restart on file changes."
            end

            command = "rerun \"#{command}\" --background"
          end

          exec command
        end
      end

      desc 'suites', 'List available test suites'
      def suites
        Suites.new.run
      end

      desc 'services stop/start', 'Start or stop background services'
      subcommand 'services', Services

      desc 'suite SUBCOMMAND ...ARGS', 'Perform suite-based operations'
      subcommand 'suite', Suite

      register(New, 'new', 'new TEST_KIT_NAME', 'Run `inferno new --help` for full help')

      desc 'version', "Output Inferno core version (#{Inferno::VERSION})"
      def version
        puts "Inferno Core v#{Inferno::VERSION}"
      end

      private

      # https://github.com/rubocop/rubocop/issues/12571 - still affects Ruby 3.1 upto Rubocop 1.63
      # rubocop:disable Naming/BlockForwarding
      def without_bundler(&block)
        if defined?(Bundler) && ENV['BUNDLE_GEMFILE']
          Bundler.with_unbundled_env(&block)
        else
          yield
        end
      end
      # rubocop:enable Naming/BlockForwarding
    end
  end
end
