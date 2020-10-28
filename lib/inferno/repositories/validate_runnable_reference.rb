module Inferno
  module Repositories
    module ValidateRunnableReference
      REFERENCE_KEYS = [:test_id, :test_group_id, :test_suite_id].freeze

      def validate
        super
        reference_error_message = check_runnable_reference
        errors.add(reference_error_message[:key], reference_error_message[:message]) if reference_error_message
      end

      def check_runnable_reference
        present_keys = REFERENCE_KEYS.select { |reference_key| send(reference_key) }

        if present_keys.length == 1
          runnable_type = present_keys.first
          id = values[runnable_type]
          reference_exists = runnable_reference_exists?(runnable_type, id)
          return if reference_exists

          { key: runnable_type, message: "of #{id} is not valid" }
        else
          { key: :base, message: "must contain exactly one of 'test_id', 'test_group_id', or 'test_suite_id'" }
        end
      end

      def runnable_reference_exists?(type, id)
        repo =
          case type
          when :test_id
            Inferno::Repositories::Tests.new
          when :test_group_id
            Inferno::Repositories::TestGroups.new
          when :test_suite_id
            Inferno::Repositories::TestSuites.new
          end

        repo.exists? id
      end
    end
  end
end
