module Inferno
  module DSL
    module InputOutputHandling
      # Define inputs
      #
      # @param identifier [Symbol] identifier for the input
      # @param other_identifiers [Symbol] array of symbols if specifying multiple inputs
      # @param input_params [Hash] options for input such as type, description, or title
      # @option input_params [String] :title Human readable title for input
      # @option input_params [String] :description Description for the input
      # @option input_params [String] :type text | textarea | radio
      # @option input_params [String] :default The default value for the input
      # @option input_params [Boolean] :optional Set to true to not require input for test execution
      # @option input_params [Hash] :options Possible input option formats based on input type
      # @option options [Array] :list_options Array of options for input formats that require a list of possible values
      # @return [void]
      # @example
      #   input :patient_id, title: 'Patient ID', description: 'The ID of the patient being searched for',
      #                     default: 'default_patient_id'
      # @example
      #   input :textarea, title: 'Textarea Input Example', type: 'textarea', optional: true
      def input(identifier, *other_identifiers, **input_params)
        if other_identifiers.present?
          [identifier, *other_identifiers].compact.each do |input_identifier|
            inputs << input_identifier
            config.add_input(input_identifier)
          end
        else
          inputs << identifier
          config.add_input(identifier, input_params)
        end
      end

      # Define outputs
      #
      # @param identifier [Symbol] identifier for the output
      # @param other_identifiers [Symbol] array of symbols if specifying multiple outputs
      # @param output_definition [Hash] options for output
      # @option output_definition [String] :type text | textarea | oauth_credentials
      # @return [void]
      # @example
      #   output :patient_id, :condition_id, :observation_id
      # @example
      #   output :oauth_credentials, type: 'oauth_credentials'
      def output(identifier, *other_identifiers, **output_definition)
        if other_identifiers.present?
          [identifier, *other_identifiers].compact.each do |output_identifier|
            outputs << output_identifier
            config.add_output(output_identifier)
          end
        else
          outputs << identifier
          config.add_output(identifier, output_definition)
        end
      end

      # @private
      def inputs
        @inputs ||= []
      end

      # @private
      def outputs
        @outputs ||= []
      end

      # @private
      def output_definitions
        config.outputs.slice(*outputs)
      end

      # @private
      def required_inputs
        available_inputs
          .reject { |_, input| input.optional }
          .map { |_, input| input.name }
      end

      # @private
      def missing_inputs(submitted_inputs)
        submitted_inputs = [] if submitted_inputs.nil?

        required_inputs.map(&:to_s) - submitted_inputs.map { |input| input[:name] }
      end

      # Define a particular order for inputs to be presented in the API/UI
      # @example
      #   group do
      #     input :input1, :input2, :input3
      #     input_order :input3, :input2, :input1
      #   end
      # @param new_input_order [Array<String,Symbol>]
      # @return [Array<String, Symbol>]
      def input_order(*new_input_order)
        return @input_order = new_input_order if new_input_order.present?

        @input_order ||= []
      end

      # @private
      def order_available_inputs(original_inputs)
        input_names = original_inputs.map { |_, input| input.name }.join(', ')

        ordered_inputs =
          input_order.each_with_object({}) do |input_name, inputs|
            key, input = original_inputs.find { |_, input| input.name == input_name.to_s }
            if input.nil?
              Inferno::Application[:logger].error <<~ERROR
                Error trying to order inputs in #{id}: #{title}:
                - Unable to find input #{input_name} in available inputs: #{input_names}
              ERROR
              next
            end
            inputs[key] = original_inputs.delete(key)
          end

        original_inputs.each do |key, input|
          ordered_inputs[key] = input
        end

        ordered_inputs
      end

      # @private
      def all_outputs
        outputs
          .map { |output_identifier| config.output_name(output_identifier) }
          .concat(children.flat_map(&:all_outputs))
          .uniq
      end

      # @private
      # Inputs available for this runnable's children. A running list of outputs
      # created by the children is used to exclude any inputs which are provided
      # by an earlier child's output.
      def children_available_inputs
        @children_available_inputs ||=
          begin
            child_outputs = []
            children.each_with_object({}) do |child, definitions|
              new_definitions = child.available_inputs.map(&:dup)
              new_definitions.each do |input, new_definition|
                existing_definition = definitions[input]

                updated_definition =
                  if existing_definition.present?
                    existing_definition.merge_with_child(new_definition)
                  else
                    new_definition
                  end

                next if child_outputs.include?(updated_definition.name.to_sym)

                definitions[updated_definition.name.to_sym] = updated_definition
              end

              child_outputs.concat(child.all_outputs).uniq!
            end
          end
      end

      # @private
      # Inputs available for the user for this runnable and all its children.
      def available_inputs
        @available_inputs ||=
          begin
            available_inputs =
              config.inputs
                .slice(*inputs)
                .each_with_object({}) do |(_, input), inputs|
                  inputs[input.name.to_sym] = input
                end

            available_inputs.each do |input, current_definition|
              child_definition = children_available_inputs[input]
              current_definition.merge_with_child(child_definition)
            end

            available_inputs = children_available_inputs.merge(available_inputs)
            order_available_inputs(available_inputs)
          end
      end
    end
  end
end
