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
      def required_inputs(prior_outputs = [])
        required_inputs =
          inputs
            .reject { |input| input_definitions[input][:optional] }
            .map { |input| config.input_name(input) }
            .reject { |input| prior_outputs.include?(input) }
        children_required_inputs = children.flat_map { |child| child.required_inputs(prior_outputs) }
        prior_outputs.concat(outputs.map { |output| config.output_name(output) })
        (required_inputs + children_required_inputs).flatten.uniq
      end

      # @private
      def missing_inputs(submitted_inputs)
        submitted_inputs = [] if submitted_inputs.nil?

        required_inputs.map(&:to_s) - submitted_inputs.map { |input| input[:name] }
      end

      # @private
      def available_input_definitions(prior_outputs = [])
        available_input_definitions =
          inputs
            .each_with_object({}) do |input, definitions|
          definitions[config.input_name(input)] =
            config.input_config(input)
        end
        available_input_definitions.reject! { |input, _| prior_outputs.include? input }

        children_available_input_definitions =
          children.each_with_object({}) do |child, definitions|
          definitions.merge!(child.available_input_definitions(prior_outputs))
        end
        prior_outputs.concat(outputs.map { |output| config.output_name(output) })
        children_available_input_definitions.merge(available_input_definitions)
      end
    end
  end
end
