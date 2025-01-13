require 'csv'
require_relative 'in_memory_repository'
require_relative '../entities/requirement'

module Inferno
  module Repositories
    # Repository that deals with persistence for the `Requirement` entity.
    class Requirements < InMemoryRepository
      def insert_from_file(path) # rubocop:disable Metrics/CyclomaticComplexity
        result = []

        CSV.foreach(path, headers: true, header_converters: :symbol) do |row|
          req_set = row[:req_set]
          id = row[:id]
          sub_requirements_field = row[:subrequirements]

          combined_id = "#{req_set}@#{id}"

          # Processing sub requirements: e.g. "170.315(g)(31)_hti-2-proposal@5,17,23,26,27,32,35,38-41"
          sub_requirements = if sub_requirements_field.nil? || sub_requirements_field.strip.blank?
                               []
                             else
                               base, ids = sub_requirements_field.split('@')
                               ids.split(',').flat_map do |item|
                                 if item.include?('-')
                                   start_range, end_range = item.split('-').map(&:to_i)
                                   (start_range..end_range).map { |num| "#{base}@#{num}" }
                                 else
                                   "#{base}@#{item}"
                                 end
                               end
                             end

          result << {
            id: combined_id,
            url: row[:url],
            requirement: row[:requirement],
            conformance: row[:conformance],
            actor: row[:actor],
            sub_requirements: sub_requirements,
            conditionality: row[:conditionality]&.downcase
          }
        end

        result.each do |raw_req|
          requirement = Entities::Requirement.new(raw_req)

          insert(requirement)
        end
      end
    end
  end
end
