module Inferno
  module CLI
    class Services < Thor
      no_commands do
        def base_command

          # We should check if we are in a Test Kit
          # but the likelihood of this file being in the working dir
          # of a user and not related to Inferno is extremely small.

          compose_file = 'docker-compose.background.yml'
          compose_path = if File.exist?("./#{compose_file}")
                          compose_file
                        else
                          File.join(__dir__, 'docker', compose_file)
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
    end
  end
end
