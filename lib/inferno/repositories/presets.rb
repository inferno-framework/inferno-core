require 'erb'

require_relative 'in_memory_repository'
require_relative '../entities/preset'

module Inferno
  module Repositories
    # Repository that deals with persistence for the `Preset` entity.
    class Presets < InMemoryRepository
      def insert_from_file(path)
        case path
        when /\.json$/
          preset_hash = JSON.parse(File.read(path))
        when /\.erb$/
          templated = ERB.new(File.read(path)).result
          preset_hash = JSON.parse(templated)
        end

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
