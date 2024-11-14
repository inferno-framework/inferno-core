require_relative 'serialize'

module Inferno
  module CLI
    class Execute
      # @private
      class JSONOutputter
        include Serialize

        def print_start_message(_options); end

        def print_around_run(_options, &)
          yield
        end

        def print_results(_options, results)
          puts serialize(results)
        end

        def print_end_message(_options); end

        def print_error(_options, exception)
          puts exception.to_json
        end
      end
    end
  end
end
