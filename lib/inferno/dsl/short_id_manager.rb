module Inferno
  module DSL
    # This module manages and locks short IDs, ensuring that short IDs
    # remain stable and do not change unexpectedly.
    module ShortIDManager
      def base_short_id_file_folder(folder = nil)
        folder ||= File.dirname(Object.const_source_location(name).first)

        return folder if File.exist?(File.join(folder, short_id_file_name))

        return folder if File.basename(File.dirname(folder)) == 'lib'

        return folder if File.dirname(folder) == folder

        base_short_id_file_folder(File.dirname(folder))
      end

      def short_id_file_name
        "#{name.demodulize.underscore}_short_id_map.yml"
      end

      def short_id_file_path
        @short_id_file_path =
          File.join(base_short_id_file_folder, short_id_file_name).freeze
      end

      # Loads and memoizes the short ID map from the YAML file.
      #
      # @return [Hash] mapping of runnable IDs to their locked short IDs
      def short_id_map
        return unless File.exist?(short_id_file_path)

        @short_id_map ||= YAML.load_file(short_id_file_path)
      end

      # @private
      # Assigns locked short IDs to all descendant runnables based on the short ID map.
      #
      # This method is called at boot time.
      #
      # @return [void]
      def assign_short_ids
        return unless short_id_map

        all_descendants.each do |runnable|
          new_short_id = short_id_map.fetch(runnable.id)
          runnable.short_id(new_short_id)
        rescue KeyError
          Inferno::Application['logger'].warn("No short id defined for #{runnable.id}")
        end
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
