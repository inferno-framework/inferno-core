require_relative 'console_outputter'

module Inferno
  module CLI
    class Execute
      # @private
      class PlainOutputter < ConsoleOutputter
        def print_error(_options, exception)
          puts "Error: #{exception.full_message(highlight: false)}"
        end

        def color
          @color ||= Pastel.new(enabled: false)
        end
      end
    end
  end
end
