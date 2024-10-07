module Inferno
  module CLI
    class Execute
      # @private
      class QuietOutputter
        # rubocop:disable Lint/UnusedMethodArgument
        def print_start_message(options)
        end

        def print_around_run(options, &)
          yield
        end

        def print_results(options, results)
        end

        def print_end_message(options)
        end

        def print_error(options, exception)
          puts "Error: #{exception.full_message}" if options[:verbose]
        end
        # rubocop:enable Lint/UnusedMethodArgument
      end
    end
  end
end
