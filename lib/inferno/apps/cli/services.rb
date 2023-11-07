module Inferno
  module CLI
    class Services < Thor
      no_commands do
        def base_command
          'docker compose -f docker-compose.background.yml'
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
    end
  end
end
