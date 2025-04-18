module Inferno
  module CLI
    class Services < Thor
      no_commands do
        def base_command
          if bundle_exec? && in_test_kit?
            compose_path = File.join(test_kit_root, 'docker-compose.background.yml')
          else
            puts 'Warning: Using global inferno services because user did not run command with `bundle exec`' if in_test_kit?

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

      private
      
      def test_kit_root
        directory = Dir.pwd
        original_directory = directory
        while directory != '/' do
          gemspec_file = Dir.glob('*.gemspec').first
          if gemspec_file && (Bundler.load_gemspec(gemspec_file).metadata['inferno_test_kit'] == 'true')
            Dir.chdir(original_directory)
            return directory
          end

          directory = File.dirname(directory)
          Dir.chdir(directory)
        end

        Dir.chdir(original_directory)
        nil
      end

      def in_test_kit?
        !!test_kit_root
      end

      def bundle_exec?
        !!ENV['BUNDLE_GEMFILE']
      end
    end
  end
end
