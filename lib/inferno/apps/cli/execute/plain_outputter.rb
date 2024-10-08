require_relative 'console_outputter'

module Inferno
  module CLI
    class Execute
      # @private
      class PlainOutputter < ConsoleOutputter

        # override to disable spinner
        def print_around_run(_options)
          puts "Running tests. This may take a while..."
          yield
        end

        def print_error(options, exception)
          puts "Error: #{exception.full_message(highlight: false)}"
          puts exception.backtrace&.join('\n')
        end

        def color
          @color ||= Pastel.new(enabled: false)
        end
      end
    end
  end
end
