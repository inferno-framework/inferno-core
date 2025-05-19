module Inferno
  module DSL
    # This module manages and locks short IDs, ensuring that short IDs
    # remain stable and do not change unexpectedly.
    module ShortIDManager
      def base_short_id_file_folder
        File.join(Dir.pwd, 'lib', name.split('::').first.underscore)
      end

      def short_id_file_name
        "#{name.demodulize.underscore}_short_id_map.yml"
      end

      def short_id_file_path
        File.join(base_short_id_file_folder, short_id_file_name).freeze
      end

      # Loads and memoizes the short ID map from the YAML file.
      #
      # @return [Hash] mapping of runnable IDs to their locked short IDs
      def short_id_map
        @short_id_map ||= YAML.load_file(short_id_file_path)
      end

      # @private
      # Assigns locked short IDs to all descendant runnables based on the short ID map.
      #
      # This method is called at boot time.
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
        Inferno::Application['logger'].warn(
          "Unable to lock short ids: no short id map found for suite `#{name}`. " \
          "To generate one, run: `bundle exec inferno suite lock_short_ids '#{id}'`. " \
          'Ignore this message if locking short ids for this suite is not needed.'
        )
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
