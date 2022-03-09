module Inferno
  module DSL
    module InputHandling
      # Define inputs
      #
      # @param identifier [Symbol] identifier for the input
      # @param other_identifiers [Symbol] array of symbols if specifying multiple inputs
      # @param input_definition [Hash] options for input such as type, description, or title
      # @option input_definition [String] :title Human readable title for input
      # @option input_definition [String] :description Description for the input
      # @option input_definition [String] :type text | textarea | radio
      # @option input_definition [String] :default The default value for the input
      # @option input_definition [Boolean] :optional Set to true to not require input for test execution
      # @option input_definition [Hash] :options Possible input option formats based on input type
      # @option options [Array] :list_options Array of options for input formats that require a list of possible values
      # @return [void]
      # @example
      #   input :patient_id, title: 'Patient ID', description: 'The ID of the patient being searched for',
      #                     default: 'default_patient_id'
      # @example
      #   input :textarea, title: 'Textarea Input Example', type: 'textarea', optional: true
      def input(identifier, *other_identifiers, **input_definition)
        if other_identifiers.present?
          [identifier, *other_identifiers].compact.each do |input_identifier|
            inputs << input_identifier
            config.add_input(input_identifier)
          end
        else
          inputs << identifier
          config.add_input(identifier, input_definition)
        end
      end

      # @private
      def inputs
        @inputs ||= []
      end

      # @private
      def input_definitions
        config.inputs.slice(*inputs)
      end

      # @private
      def required_inputs
        available_input_definitions
          .reject { |_, input_definition| input_definition.optional }
          .map { |_, input_definition| input_definition.name }
      end

      # @private
      def missing_inputs(submitted_inputs)
        submitted_inputs = [] if submitted_inputs.nil?

        required_inputs.map(&:to_s) - submitted_inputs.map { |input| input[:name] }
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
      def children_available_input_definitions
        @children_available_input_definitions ||=
          begin
            child_outputs = []
            children.each_with_object({}) do |child, definitions|
              new_definitions = child.available_input_definitions.map(&:dup)
              new_definitions.each do |input, new_definition|
                current_definition = definitions[input]

                if current_definition.present?
                  definitions[input] = current_definition.merge_with_child(new_definition)
                elsif !child_outputs.include? new_definition.name.to_sym
                  definitions[input] = new_definition
                end
              end

              child_outputs.concat(child.all_outputs).uniq!
            end
          end
      end

      # @private
      # Inputs available for the user for this runnable and all its children.
      def available_input_definitions
        @available_input_definitions ||=
          begin
            available_input_definitions = input_definitions

            available_input_definitions.each do |input, current_definition|
              child_definition = children_available_input_definitions[input]
              current_definition.merge_with_child(child_definition)
            end

            children_available_input_definitions
              .merge(available_input_definitions)
          end
      end
    end
  end
end
