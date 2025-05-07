module Inferno
  module DSL
    # This module manages and locks short IDs, ensuring that short IDs
    # remain stable and do not change unexpectedly.
    module ShortIDManager
      def short_id_file_path
        File.join('lib', "#{name.underscore}_short_id_map.yml")
      end

      # Loads and memoizes the short ID map from the YAML file.
      #
      # @return [Hash] mapping of runnable IDs to their locked short IDs
      def short_id_map
        @short_id_map ||= YAML.load_file(short_id_file_path)
      end

      # Assigns locked short IDs to all descendant runnables based on the short ID map.
      #
      # @example
      #   module TestKitName
      #     class Suite < Inferno::TestSuite
      #       id :suite_id
      #
      #       group from: 'group_1'
      #       group from: 'group_2'
      #       group from: 'group_3'
      #
      #       assign_short_ids
      #     end
      #   end
      #
      #   This will assign the short_ids defined in
      #   lib/test_kit_name/suite_short_id_map.yml to each group/test.
      #
      # @return [void]
      def assign_short_ids
        all_descendants.each do |runnable|
          new_short_id = short_id_map.fetch(runnable.id)
          runnable.short_id(new_short_id)
        rescue KeyError
          Inferno::Application['logger'].warn("No short id defined for #{runnable.id}")
        end
      rescue Errno::ENOENT
        Inferno::Application['logger'].warn('No short id map found')
      end

      # Builds and memoizes the current mapping of runnable IDs to their short IDs.
      #
      # @return [Hash] current short ID mapping
      def current_short_id_map
        @current_short_id_map ||=
          all_descendants.each_with_object({}) do |runnable, mapping|
            mapping[runnable.id] = runnable.short_id
          end
      end
    end
  end
end
