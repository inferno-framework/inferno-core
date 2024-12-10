require_relative 'console'
require_relative 'evaluate'
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
      desc 'evaluate', 'Run a FHIR Data Evaluator.'
      long_desc <<-LONGDESC
        Evaluate FHIR data in the context of a given Implementation Guide,
        by applying a set of predefined rules designed to check that datasets are comprehensive.
        Issues identified will be printed to console or to a json file.

        You must have background services running: `bundle exec inferno services start`

        Run the evaluation CLI with

        `bundle exec inferno evaluate ig_path`

        Examples:

        # Load the us core ig and evaluate the data in the provided example folder. If there are examples in the IG already, they will be ignored.
        `bundle exec inferno evaluate ./uscore.tgz -d ./package/example`

        # Loads the us core ig and evaluate the data included in the IG's example folder
        `bundle exec inferno evaluate ./uscore.tgz`

        # Loads the us core ig and evaluate the data included in the IG's example folder, with results redirected to outcome.json as an OperationOutcome
        `bundle exec inferno evaluate ./uscore.tgz --output outcome.json`
      LONGDESC
      # TODO: Add options below as arguments
      option :data_path,
             aliases: ['-d'],
             type: :string,
             desc: 'Example FHIR data path'
      # TODO: implement option of exporting result as OperationOutcome
      option :output,
             aliases: ['-o'],
             type: :string,
             desc: 'Export evaluation result to outcome.json as an OperationOutcome'
      def evaluate(ig_path)
        Evaluate.new.run(ig_path, options[:data_path], Logger::INFO)
      end

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
        Run Inferno tests in the command line. Exits with 0 only if test entity passes.
        Must be run with test kit as working directory.

        You must have background services running: `bundle exec inferno services start`

        You can view suite ids with: `bundle exec inferno suites`

        You can select an output format with the `--outputter` option. Current outputters
        are console (default), plain, quiet, and json. JSON-formatted output will copy
        Inferno's REST API: https://inferno-framework.github.io/inferno-core/api-docs/#/Result.

        Examples:

            (These examples only work from within the inferno_core directory).

            `bundle exec inferno execute --suite dev_validator \
                                        --inputs "url:https://hapi.fhir.org/baseR4" \
                                                 patient_id:1234321`
            => Outputs test results

            `bundle exec inferno execute --suite dev_validator \
                                         --inputs "url:https://hapi.fhir.org/baseR4" \
                                                  patient_id:1234321 \
                                         --tests 1.01 1.02`
            => Run specific tests from suite

            `bundle exec inferno execute --suite dev_validator \
                                         --inputs "url:https://hapi.fhir.org/baseR4" \
                                                  patient_id:1234321 \
                                         --outputter json`
            => Outputs test results in JSON
      END_OF_HELP
      desc 'execute', 'Run Inferno tests in command line'
      long_desc EXECUTE_HELP, wrap: false
      option :suite,
             aliases: ['-s'],
             type: :string,
             desc: 'Test suite id to run or to select groups and tests from',
             banner: 'id'
      option :suite_options,
             aliases: ['-u'],
             type: :hash,
             desc: 'Suite options'
      option :groups,
             aliases: ['-g'],
             type: :array,
             desc: 'Series of test group short ids (AKA sequence number) to run, requires suite'
      option :tests,
             aliases: ['-t'],
             type: :array,
             desc: 'Series of test short ids (AKA sequence number) to run, requires suite'
      option :short_ids,
             aliases: ['-r'],
             type: :array,
             desc: 'Series of test or group short ids (AKA sequence number) to run, requires suite'
      option :inputs,
             aliases: ['-i'],
             type: :hash,
             desc: 'Inputs (i.e: --inputs=foo:bar goo:baz); will merge and override preset inputs'
      option :preset_id,
             aliases: ['-P'],
             type: :string,
             desc: 'Inferno preset id; cannot be used with `--preset-file`'
      option :preset_file,
             aliases: ['-p'],
             type: :string,
             desc: 'Path to an Inferno preset file for inputs; cannot be used with `--preset-id`'
      option :outputter,
             aliases: ['-o'],
             default: 'console',
             desc: 'Select an outputter format: console | plain | json | quiet'
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
        Execute.boot_full_inferno
        Execute.new.run(options.dup) # dup to unfreeze Thor options
      end

      # https://github.com/rails/thor/issues/244 - Make Thor exit(1) on Errors/Exceptions
      def self.exit_on_failure?
        true
      end

      private

      # https://github.com/rubocop/rubocop/issues/12571 - still affects Ruby 3.1 upto Rubocop 1.63
      def without_bundler(&)
        if defined?(Bundler) && ENV['BUNDLE_GEMFILE']
          Bundler.with_unbundled_env(&)
        else
          yield
        end
      end
    end
  end
end
