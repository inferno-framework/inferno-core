module Inferno
  module Exceptions
    class TestResultException < RuntimeError
    end

    class AssertionException < TestResultException
      def result
        'fail'
      end
    end

    class SkipException < TestResultException
      def result
        'skip'
      end
    end

    class OmitException < TestResultException
      def result
        'omit'
      end
    end

    class PassException < TestResultException
      def result
        'pass'
      end
    end

    class WaitException < TestResultException
      def result
        'wait'
      end
    end

    class CancelException < TestResultException
      def result
        'cancel'
      end
    end

    # ErrorInValidatorException is used when an exception occurred in
    # calling the validator service, for example a connection timeout
    # or an unexpected response format.
    # Note: This class extends TestResultException instead of RuntimeError
    # to bypass printing the stack trace in the UI, since
    # the stack trace of this exception is not likely be useful.
    # Instead the message should point to where in the validator an error occurred.
    class ErrorInValidatorException < TestResultException
      def result
        'error'
      end
    end

    class ParentNotLoadedException < RuntimeError
      def initialize(klass, id)
        super("No #{klass.name.demodulize} found with id '#{id}'")
      end
    end

    class ValidatorNotFoundException < RuntimeError
      def initialize(validator_name)
        super("No '#{validator_name}' validator found")
      end
    end

    class FhirpathNotFoundException < RuntimeError
      def initialize(fhirpath_name)
        super("No '#{fhirpath_name}' FHIRPath evaluator found")
      end
    end

    # ErrorInFhirpathException is used when an exception occurred in
    # calling the FHIRPath service, for example a connection timeout
    # or an unexpected response format.
    # Note: This class extends TestResultException instead of RuntimeError
    # to bypass printing the stack trace in the UI, since
    # the stack trace of this exception is not likely be useful.
    # Instead the message should point to where in the fhirpath evaluator an error occurred.
    class ErrorInFhirpathException < TestResultException
      def result
        'error'
      end
    end

    class RequiredInputsNotFound < RuntimeError
      def initialize(missing_inputs)
        super("Missing the following required inputs: #{missing_inputs.join(', ')}")
      end
    end

    class NotUserRunnableException < RuntimeError
      def initialize
        super('The chosen runnable must be run as part of a group')
      end
    end

    class UnknownAttributeException < RuntimeError
      def initialize(attributes, klass)
        attributes_string = attributes.map { |attribute| "'#{attribute}'" }.join(', ')
        super("Unknown attributes for #{klass.name}: #{attributes_string}")
      end
    end

    class UnknownSessionDataType < RuntimeError
      def initialize(output)
        super("Unknown type '#{output[:type]}' for '#{output[:name]}'.")
      end
    end

    class BadSessionDataType < RuntimeError
      def initialize(name, expected_class_names, actual_class)
        super("Expected '#{name}' to be a #{expected_class_names}, but found a #{actual_class.name}.")
      end
    end

    class InvalidRunnableIdException < StandardError
      def initialize(id)
        super("ID '#{id}' exceeds the maximum id length of 255 characters")
      end
    end

    class DuplicateEntityIdException < StandardError
      def initialize(id)
        super("ID '#{id}' already exists. Ensure the uniqueness of the IDs.")
      end
    end

    class RunnableChildNotFoundException < StandardError
      def initialize(id, runnable)
        super("Could not find a child with an ID ending in '#{id}' for '#{runnable}'.")
      end
    end
  end
end
