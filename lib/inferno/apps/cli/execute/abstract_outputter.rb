
module Inferno
  module CLI
    class Execute

      # Subclass AbstractOutputter to implement your own outputter
      class AbstractOutputter

        # @see Inferno::CLI::Main#execute for options
        def print_start_message(options)
        end

        # Implementation MUST call `yield`
        # @see Inferno::CLI::Main#execute for options
        def print_around_run(options, &block)
        end

        # @param results [Array<Inferno::Entity::Result>]
        # @see Inferno::CLI::Main#execute for options
        def print_results(options, results)
        end

        # @see Inferno::CLI::Main#execute for options
        def print_end_message(options)
        end

        # Implementation MUST NOT re-raise exception or exit
        # @param exception [Exception]
        def print_error(exception)
        end

      end
    end
  end
end
