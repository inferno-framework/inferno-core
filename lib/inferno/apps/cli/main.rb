require_relative 'console'
require_relative 'migration'
require_relative 'services'
require_relative 'suite'
require_relative 'suites'
require_relative 'new/new'

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
      option :watch,
             default: false,
             type: :boolean,
             desc: 'Automatically restart Inferno when a file is changed.'
      def start
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

      desc 'suites', 'List available test suites'
      def suites
        Suites.new.run
      end

      desc 'services stop/start', 'Start or stop background services'
      subcommand 'services', Services

      desc 'suite SUBCOMMAND ...ARGS', 'Perform suite-based operations'
      subcommand 'suite', Suite

      map 'new' => :new_app
      desc 'new TEST_KIT_NAME [-i IG_URL]', 'Generate a new Inferno test kit'
      option :implementation_guide,
             default: nil,
             type: :string,
             aliases: '-i',
             desc: 'URL to an implementation guide to load'
      def new_app(name)
        New.new().run(name, options[:implementation_guide])
      end
    end
  end
end
