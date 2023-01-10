require_relative 'repository'
require_relative '../utils/preset_processor'

module Inferno
  module Repositories
    # Repository that deals with persistence for the `TestSession` entity.
    class TestSessions < Repository
      include Import[
                results_repo: 'inferno.repositories.results',
                session_data_repo: 'inferno.repositories.session_data',
                presets_repo: 'inferno.repositories.presets'
              ]

      def json_serializer_options
        {
          include: {
            results: results_repo.json_serializer_options,
            test_runs: {}
          }
        }
      end

      def create(params)
        raw_suite_options = params[:suite_options]
        suite_options =
          if raw_suite_options.blank?
            '[]'
          else
            JSON.generate(raw_suite_options.map(&:to_hash))
          end

        super(params.merge(suite_options:))
      end

      def results_for_test_session(test_session_id)
        test_session_hash =
          self.class::Model
            .find(id: test_session_id)
            .to_json_data(json_serializer_options)
            .deep_symbolize_keys!

        test_session_hash[:results]
          .map! { |result| results_repo.build_entity(result) }
      end

      def apply_preset(test_session, preset_id)
        preset = presets_repo.find(preset_id)
        Utils::PresetProcessor.new(preset, test_session).processed_inputs.each do |input|
          session_data_repo.save(input.merge(test_session_id: test_session.id))
        end
      end

      def build_entity(params)
        suite_options = JSON.parse(params[:suite_options] || '[]').map do |suite_option_hash|
          suite_option_hash.deep_symbolize_keys!
          suite_option_hash[:id] = suite_option_hash[:id].to_sym
          DSL::SuiteOption.new(suite_option_hash)
        end

        final_params = params.merge(suite_options:)
        add_non_db_entities(final_params)
        entity_class.new(final_params)
      end

      class Model < Sequel::Model(db)
        include Import[test_suites_repo: 'inferno.repositories.test_suites']

        one_to_many :results,
                    eager: [:messages, :requests],
                    class: 'Inferno::Repositories::Results::Model',
                    key: :test_session_id
        one_to_many :test_runs, class: 'Inferno::Repositories::TestRuns::Model', key: :test_session_id

        def before_create
          self.id = SecureRandom.uuid
          time = Time.now
          self.created_at ||= time
          self.updated_at ||= time
          super
        end

        def validate
          super
          errors.add(:test_suite_id, 'cannot be empty') if test_suite_id.blank?
          unless test_suites_repo.exists? test_suite_id # rubocop:disable Style/GuardClause
            errors.add(:test_suite_id, "'#{test_suite_id}' is not valid")
          end
        end
      end
    end
  end
end
