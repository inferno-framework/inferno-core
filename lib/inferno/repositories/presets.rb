require_relative 'in_memory_repository'
require_relative '../entities/preset'

module Inferno
  module Repositories
    # Repository that deals with persistence for the `Preset` entity.
    class Presets < InMemoryRepository
      def insert_from_file(path)
        preset_hash = JSON.parse(File.read(path))
        preset_hash.deep_symbolize_keys!
        preset_hash[:id] ||= SecureRandom.uuid
        preset = Entities::Preset.new(preset_hash)

        insert(preset)
      end

      def presets_for_suite(suite_id)
        all.select { |preset| preset.test_suite_id.to_s == suite_id.to_s }
      end
    end
  end
end
