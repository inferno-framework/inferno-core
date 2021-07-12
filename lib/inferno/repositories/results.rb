require_relative 'validate_runnable_reference'

module Inferno
  module Repositories
    class Results < Repository
      include Import[
                messages_repo: 'repositories.messages',
                requests_repo: 'repositories.requests',
                tests_repo: 'repositories.tests',
                groups_repo: 'repositories.test_groups',
                suites_repo: 'repositories.test_suites'
              ]

      def create(params)
        messages = params.delete(:messages) || []
        requests = params.delete(:requests) || []
        super(params).tap do |result|
          messages.each { |message| messages_repo.create(message.merge(result_id: result.id)) }
          requests.each { |request| requests_repo.create(request.to_hash.merge(result_id: result.id)) }
        end
      end

      def build_entity(params)
        runnable =
          if params[:test_id]
            { test: tests_repo.find(params[:test_id]) }
          elsif params[:test_group_id]
            { test_group: groups_repo.find(params[:test_group_id]) }
          elsif params[:test_suite_id]
            { test_suite: suites_repo.find(params[:test_suite_id]) }
          else
            {}
          end
        entity_class.new(params.merge(runnable))
      end

      def find_waiting_result(test_run_id:)
        result_hash =
          Model
            .where(test_run_id: test_run_id, result: 'wait')
            .where { test_id !~ nil }
            .limit(1)
            .to_a
            .first
            &.to_hash

        return nil if result_hash.nil?

        build_entity(result_hash)
      end

      def current_results_for_test_session(test_session_id)
        self.class::Model
          .current_results_for_test_session(test_session_id)
          .eager(:messages)
          .eager(requests: proc { |requests| requests.select(*Entities::Request::SUMMARY_FIELDS) })
          .all
          .map! do |result_hash|
            build_entity(
              result_hash
                .to_json_data(json_serializer_options)
                .deep_symbolize_keys!
            )
          end
      end

      def pass_waiting_result(result_id, message = nil)
        update(result_id, result: 'pass', result_message: message)
      end

      def json_serializer_options
        {
          include: {
            messages: {},
            requests: {
              only: Entities::Request::SUMMARY_FIELDS
            }
          }
        }
      end

      class Model < Sequel::Model(db)
        include ValidateRunnableReference

        CURRENT_RESULTS_SQL = <<~SQL.gsub(/\s+/, ' ').freeze
          SELECT * FROM results a
          WHERE a.id in  (
            SELECT id
            FROM results b
            WHERE (b.test_session_id = a.test_session_id AND b.test_id = a.test_id) OR
                  (b.test_session_id = a.test_session_id AND b.test_group_id = a.test_group_id) OR
                  (b.test_session_id = a.test_session_id AND b.test_suite_id = a.test_suite_id)
            ORDER BY created_at DESC
            LIMIT 1
          ) AND test_session_id = ?
        SQL

        one_to_many :messages, class: 'Inferno::Repositories::Messages::Model', key: :result_id
        one_to_many :requests, class: 'Inferno::Repositories::Requests::Model', key: :result_id
        many_to_one :test_run, class: 'Inferno::Repositories::TestRuns::Model', key: :test_run_id
        many_to_one :test_session, class: 'Inferno::Repositories::TestSessions::Model', key: :test_session_id

        def before_create
          self.id = SecureRandom.uuid
          time = Time.now
          self.created_at ||= time
          self.updated_at ||= time
          super
        end

        def validate
          super
          errors.add(:result, "'#{result}' is not valid") unless Entities::Result::RESULT_OPTIONS.include?(result)
        end

        def self.current_results_for_test_session(test_session_id)
          fetch(CURRENT_RESULTS_SQL, test_session_id)
        end
      end
    end
  end
end
