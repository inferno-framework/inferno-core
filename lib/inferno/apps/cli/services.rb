module Inferno
  module CLI
    class Services < Thor
      no_commands do
        def base_command
          gemspec_file = Dir.glob('*.gemspec').first

          if ENV['BUNDLE_GEMFILE'] && File.exist?(gemspec_file) && Bundler.load_gemspec(gemspec_file).metadata['inferno_test_kit'] == 'true'
            compose_path = './docker-compose.background.yml' # Any way to fetch test kit root?
          else
            compose_path = File.join(__dir__, 'services', 'docker-compose.global.yml')
          end

          "docker compose -f #{compose_path}"
        end
      end

      desc 'start', 'Start background services'
      option :foreground,
             default: false,
             type: :boolean,
             desc: 'Run services in foreground'
      def start
        command = "#{base_command} up"
        command += ' -d' unless options[:foreground]

        system command
      end

      desc 'stop', 'Stop background services'
      def stop
        system "#{base_command} down"
      end

      desc 'build', 'Build background service images'
      def build
        system "#{base_command} build"
      end

      desc 'pull', 'Pull background service images'
      def pull
        system "#{base_command} pull"
      end

      desc 'logs', 'Display the logs for the background services'
      option :follow,
             default: false,
             aliases: [:f],
             type: :boolean,
             desc: 'Follow log output'
      option :tail,
             banner: 'string',
             default: 'all',
             desc: 'Number of lines to show from the end of the logs for each container'
      def logs
        command = "#{base_command} logs"
        command += ' -f' if options[:follow]
        command += " --tail #{options[:tail]}" if options[:tail]

        system command
      end

      desc 'path', 'Output path to the compose file in use'
      def path
        puts base_command.sub('docker compose -f ', '')
      end
    end
  end
end
