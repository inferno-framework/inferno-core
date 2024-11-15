module Inferno
  module CLI
    class Execute
      # @private
      class QuietOutputter
        def print_start_message(_options); end

        def print_around_run(_options, &)
          yield
        end

        def print_results(_options, _results); end

        def print_end_message(_options); end

        def print_error(options, exception)
          puts "Error: #{exception.full_message}" if options[:verbose]
        end
      end
    end
  end
end
