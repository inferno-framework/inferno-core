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
      # @option input_params [String] :type text | textarea | radio | checkbox | oauth_credentials
      # @option input_params [String] :default The default value for the input
      # @option input_params [Boolean] :optional Set to true to not require input for test execution
      # @option input_params [Boolean] :locked If true, the user can not alter the value
      # @option input_params [Boolean] :hidden If true, the input will not be visible to the user in the UI
      # @option input_params [Hash] :options Possible input option formats based on input type
      # @option options [Array] :list_options Array of options for input formats
      #   that require a list of possible values (radio and checkbox)
      # @option input_params [Hash] :enable_when Conditions for showing the input and determining
      #   whether it is required. Must be a Hash
      #   with String :input_name (the name of the controlling input) and String :value (the value
      #   that triggers visibility). For checkbox inputs the value must be a JSON-encoded sorted
      #   array, e.g. '["a","b"]'.
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
            children
              .reject { |child| child.inputs.include? input_identifier }
              .each do |child|
                child.input(input_identifier)
              end
          end
        else
          inputs << identifier
          config.add_input(identifier, input_params)
          children
            .reject { |child| child.inputs.include? identifier }
            .each do |child|
              child.input(identifier, **input_params)
            end
        end
      end

      # Define outputs
      #
      # @param identifier [Symbol] identifier for the output
      # @param other_identifiers [Symbol] array of symbols if specifying multiple outputs
      # @param output_definition [Hash] options for output
      # @option output_definition [String] :type text, textarea, or oauth_credentials
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
            children
              .reject { |child| child.outputs.include? output_identifier }
              .each do |child|
                child.output(output_identifier)
              end
          end
        else
          outputs << identifier
          config.add_output(identifier, output_definition)
          children
            .reject { |child| child.outputs.include? identifier }
            .each do |child|
              child.output(identifier, **output_definition)
            end
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
      def required_inputs(selected_suite_options, submitted_inputs = nil)
        input_values = (submitted_inputs || []).to_h { |input| [input[:name].to_s, input[:value]] }

        available = available_inputs(selected_suite_options)
        available
          .reject { |_, input| input.optional || !input.enabled?(input_values, available) }
          .map { |_, input| input.name }
      end

      # @private
      def missing_inputs(submitted_inputs, selected_suite_options)
        submitted_inputs = [] if submitted_inputs.nil?

        required_input_names = required_inputs(selected_suite_options, submitted_inputs).map(&:to_s)
        submitted_input_names = submitted_inputs.map { |input| input[:name] }

        required_input_names - submitted_input_names
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
          .concat(all_children.flat_map(&:all_outputs))
          .uniq
      end

      # @private
      # Inputs available for this runnable's children. A running list of outputs
      # created by the children is used to exclude any inputs which are provided
      # by an earlier child's output.
      def children_available_inputs(selected_suite_options = nil)
        child_outputs = []
        children(selected_suite_options).each_with_object({}) do |child, definitions|
          new_definitions = child.available_inputs(selected_suite_options).map(&:dup)
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

      # @private
      # Inputs available for the user for this runnable and all its children.
      def available_inputs(selected_suite_options = nil)
        available_inputs =
          config.inputs
            .slice(*inputs)
            .each_with_object({}) do |(_, input), inputs|
              inputs[input.name.to_sym] = Entities::Input.new(**input.to_hash)
            end

        # children_available_inputs walks the entire subtree, so it is computed once here
        # rather than once per input. merge_with_child only mutates its receiver, so the
        # child definitions are safe to reuse for the merge below.
        child_inputs = children_available_inputs(selected_suite_options)

        available_inputs.each do |input, current_definition|
          current_definition.merge_with_child(child_inputs[input])
        end

        order_available_inputs(child_inputs.merge(available_inputs))
      end

      # @private
      # Automatically detect circular `enable_when` dependencies among this
      # runnable's own available inputs (e.g. input `a` is enabled_when `b`,
      # which is itself enabled_when `a`). Such inputs silently evaluate as
      # disabled at runtime (see `Entities::Input#enabled?`'s `visited`
      # guard). Note `enable_when` is an uninheritable attribute -- it only
      # has meaning at the level it's declared -- so a cycle local to a group
      # or test can be masked if a parent re-declares the same input name
      # without repeating `enable_when`; checking every runnable in the tree
      # (not just the suite) is what catches those.
      def enable_when_cycle_messages
        detect_enable_when_cycles.map do |cycle|
          chain = (cycle + [cycle.first]).join(' -> ')
          "Circular enable_when dependency detected in input '#{cycle.first}': #{chain}. "
        end
      end

      # @private
      def detect_enable_when_cycles
        depends_on = enable_when_edges
        globally_visited = {}

        depends_on.each_key.filter_map do |start_name|
          next if globally_visited[start_name]

          follow_enable_when_chain(start_name, depends_on, globally_visited)
        end
      end

      # @private
      # Maps each input's name to the name of the input it depends on via
      # `enable_when`, for every input in this runnable that has one.
      def enable_when_edges
        available_inputs.each_value.with_object({}) do |input, depends_on|
          depends_on[input.name] = input.enable_when[:input_name] if input.enable_when.present?
        end
      end

      # @private
      # Follows the `enable_when` chain starting at `start_name`, marking
      # every node visited along the way. Returns the cycle (as an array of
      # input names) if one is found, otherwise nil.
      def follow_enable_when_chain(start_name, depends_on, globally_visited)
        path = []
        node = start_name

        until node.nil? || globally_visited[node]
          break if path.index(node)

          path << node
          node = depends_on[node]
        end

        path.each { |name| globally_visited[name] = true }

        cycle_start_index = path.index(node)
        cycle_start_index && path[cycle_start_index..]
      end
    end
  end
end
