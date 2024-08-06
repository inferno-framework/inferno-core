module Inferno
  module Utils
    module PersistInputs

      def persist_inputs(params, test_run)
        available_inputs = test_run.runnable.available_inputs
        params[:inputs]&.each do |input_params|
          input =
            available_inputs
              .find { |_, runnable_input| runnable_input.name == input_params[:name] }
              &.last

          if input.nil?
            Inferno::Application['logger'].warn(
              "Unknown input `#{input_params[:name]}` for #{test_run.runnable.id}: #{test_run.runnable.title}"
            )
            next
          end

          session_data_repo.save(
            test_session_id: test_run.test_session_id,
            name: input.name,
            value: input_params[:value],
            type: input.type
          )
        end
      end

    end
  end
end
