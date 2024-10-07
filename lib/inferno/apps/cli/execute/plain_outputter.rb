require_relative 'console_outputter'

module Inferno
  module CLI
    class Execute
      # @private
      class PlainOutputter < ConsoleOutputter
        def color
          @color ||= Pastel.new(enabled: false)
        end
      end
    end
  end
end
