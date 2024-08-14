require_relative 'console'
require_relative 'migration'
require_relative 'services'
require_relative 'suite'
require_relative 'suites'
require_relative 'new'
require_relative '../../version'
require_relative 'execute'

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

      EXECUTE_HELP = <<~END_OF_HELP.freeze
        Run Inferno tests in the command line. Exits with 0 only if test suite passes. Must be run from test kit as working directory.

        You must have background services running: `bundle exec inferno services start`

        You can view suite ids with: `bundle exec inferno suites`

        Examples:

            `bundle exec inferno execute --suite dev_validator --inputs "url:https://hapi.fhir.org/baseR4" patient_id:1234321`
            => Outputs test results
      END_OF_HELP
      desc 'execute', 'Run Inferno tests in command line'
      long_desc EXECUTE_HELP, wrap: false
      option :suite,
             aliases: ['-s'],
             type: :string,
             desc: 'Test Suite ID to run',
             banner: 'id'
      option :suite_options,
             aliases: ['-o'],
             type: :hash,
             desc: 'Suite options'
      option :inputs,
             aliases: ['-i'],
             type: :hash,
             desc: 'Inputs (i.e: --inputs=foo:bar goo:baz)'
      option :verbose,
             aliases: ['-v'],
             type: :boolean,
             default: false,
             desc: 'Output additional information for debugging'
      option :help,
             aliases: ['-h'],
             type: :boolean,
             default: false,
             desc: 'Display this message'
      def execute
        Execute.new.run(options)
      end

      # https://github.com/rails/thor/issues/244 - Make Thor exit(1) on Errors/Exceptions
      def self.exit_on_failure?
        true
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
