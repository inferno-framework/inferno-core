require 'erb'

require_relative 'in_memory_repository'
require_relative '../entities/preset'

module Inferno
  module Repositories
    # Repository that deals with persistence for the `Preset` entity.
    class Presets < InMemoryRepository
      def insert_from_file(path)
        raw_contents =
          case path
          when /\.json$/
            File.read(path)
          when /\.erb$/
            ERB.new(File.read(path)).result
          end

        if Application['base_url'].start_with? 'https://inferno-qa.healthit.gov'
          raw_contents.gsub!('https://inferno.healthit.gov', 'https://inferno-qa.healthit.gov')
        end

        preset_hash = JSON.parse(raw_contents)

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
