require 'csv'
require_relative 'in_memory_repository'
require_relative '../entities/requirement'

module Inferno
  module Repositories
    # Repository that deals with persistence for the `Requirement` entity.
    class Requirements < InMemoryRepository
      def insert_from_file(path)
        result = []

        CSV.foreach(path, headers: true, header_converters: :symbol) do |row|
          req_set = row[:req_set]
          id = row[:id]
          sub_requirements_field = row[:subrequirements]

          combined_id = "#{req_set}@#{id}"

          # Processing sub requirements: e.g. "170.315(g)(31)_hti-2-proposal@5,17,23,26,27,32,35,38-41"
          sub_requirements = Inferno::Entities::Requirement.expand_requirement_ids(sub_requirements_field)

          result << {
            requirement_set: req_set,
            id: combined_id,
            url: row[:url],
            requirement: row[:requirement],
            conformance: row[:conformance],
            actor: row[:actor].split(',').map(&:strip),
            sub_requirements: sub_requirements,
            conditionality: row[:conditionality]&.downcase,
            not_tested_reason: row[:not_tested_reason],
            not_tested_details: row[:not_tested_details]
          }
        end

        result.each do |raw_req|
          requirement = Entities::Requirement.new(raw_req)

          insert(requirement)
        end
      end

      def requirements_for_actor(requirement_set, actor)
        all.select { |requirement| requirement.requirement_set == requirement_set && requirement.actor?(actor) }
      end

      def filter_requirements_by_ids(ids)
        all.select { |requirement| ids.include?(requirement.id) }
      end

      def requirements_for_suite(test_suite_id, test_session_id = nil)
        test_suite = Inferno::Repositories::TestSuites.new.find(test_suite_id)
        selected_suite_options =
          if test_session_id.present?
            Inferno::Repositories::TestSessions.new.find(test_session_id).suite_options
          else
            []
          end

        requirement_sets =
          test_suite
            .requirement_sets
            .select do |set|
              set.suite_options.all? do |set_option|
                selected_suite_options.blank? || selected_suite_options.include?(set_option)
              end
            end

        requirements =
          complete_requirement_set_requirements(requirement_sets) +
          filtered_requirement_set_requirements(requirement_sets)

        add_referenced_requirement_set_requirements(requirements, requirement_sets).uniq
      end

      def complete_requirement_set_requirements(requirement_sets)
        requirement_sets.select(&:complete?)
          .flat_map do |requirement_set|
            all.select do |requirement|
              requirement.requirement_set == requirement_set.identifier &&
                requirement.actor?(requirement_set.actor)
            end
          end
      end

      def filtered_requirement_set_requirements(requirement_sets)
        requirement_sets.select(&:filtered?)
          .flat_map do |requirement_set|
            requirement_set
              .expand_requirement_ids
              .map { |requirement_id| find(requirement_id) }
              .select { |requirement| requirement.actor?(requirement_set.actor) }
          end
      end

      def add_referenced_requirement_set_requirements( # rubocop:disable Metrics/CyclomaticComplexity
        requirements_to_process,
        requirement_sets,
        processed_requirements = []
      )
        return processed_requirements if requirements_to_process.blank?

        referenced_requirement_sets = requirement_sets.select(&:referenced?)

        referenced_requirement_ids =
          requirements_to_process
            .flat_map(&:sub_requirements)
            .select do |requirement_id|
              referenced_requirement_sets.any? do |set|
                requirement_id.start_with?("#{set.identifier}@") && (find(requirement_id).actor?(set.actor))
              end
            end

        new_requirements =
          referenced_requirement_ids.map { |id| find(id) } - requirements_to_process - processed_requirements

        add_referenced_requirement_set_requirements(
          new_requirements,
          referenced_requirement_sets,
          (processed_requirements + requirements_to_process).uniq
        )
      end
    end
  end
end
