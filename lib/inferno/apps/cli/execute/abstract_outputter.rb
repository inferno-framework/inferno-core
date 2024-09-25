module Inferno
  module CLI
    class Execute
      # Subclass AbstractOutputter to implement your own outputter
      #
      # @abstract
      # rubocop:disable Lint/UnusedMethodArgument
      class AbstractOutputter
        # @see Inferno::CLI::Main#execute for options
        def print_start_message(options)
        end

        # Implementation MUST call `yield`
        # @see Inferno::CLI::Main#execute for options
        def print_around_run(options, &)
        end

        # @see Inferno::CLI::Main#execute for options
        # @param results [Array<Inferno::Entity::Result>]
        def print_results(options, results)
        end

        # @see Inferno::CLI::Main#execute for options
        def print_end_message(options)
        end

        # Implementation MUST NOT re-raise exception or exit
        # @see Inferno::CLI::Main#execute for options
        # @param exception [Exception]
        def print_error(options, exception)
        end
      end
      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
