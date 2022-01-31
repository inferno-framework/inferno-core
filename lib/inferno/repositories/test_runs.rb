require_relative 'validate_runnable_reference'

module Inferno
  module Repositories
    class TestRuns < Repository
      include Import[results_repo: 'repositories.results']

      def json_serializer_options
        {
          include: {
            results: results_repo.json_serializer_options
          }
        }
      end

      def build_entity(params)
        super.tap do |test_run|
          test_run&.results&.map! do |result|
            result.is_a?(Entities::Result) ? result : Entities::Result.new(result)
          end
        end
      end

      def results_for_test_run(test_run_id)
        test_run_hash =
          self.class::Model
            .find(id: test_run_id)
            .to_json_data(json_serializer_options)
            .deep_symbolize_keys!

        test_run_hash[:results]
          .map! { |result| results_repo.build_entity(result) }
      end

      def find_latest_waiting_by_identifier(identifier)
        test_run_hash =
          self.class::Model
            .where(status: 'waiting')
            .where(identifier: identifier)
            .where { wait_timeout >= Time.now }
            .order(Sequel.desc(:updated_at))
            .limit(1)
            .to_a
            &.first
            &.to_hash

        return nil if test_run_hash.nil?

        build_entity(test_run_hash)
      end

      def last_test_run(test_session_id)
        test_run_hash =
          self.class::Model
            .where(test_session_id: test_session_id)
            .order(Sequel.desc(:updated_at))
            .limit(1)
            .to_a
            .map { |record| record.to_json_data(json_serializer_options).deep_symbolize_keys! }
            &.first
            &.to_hash

        return nil if test_run_hash.nil?

        build_entity(test_run_hash)
      end

      def status_for_test_run(id)
        self.class::Model.where(id: id).get(:status)
      end

      def mark_as_running(test_run_id)
        update(test_run_id, status: 'running')
      end

      def mark_as_done(test_run_id)
        update(test_run_id, status: 'done')
      end

      def mark_as_waiting(test_run_id, identifier, timeout)
        update(
          test_run_id,
          status: 'waiting',
          identifier: identifier,
          wait_timeout: Time.now + timeout.seconds
        )
      end

      def mark_as_no_longer_waiting(test_run_id)
        update(
          test_run_id,
          status: 'queued',
          identifier: nil,
          wait_timeout: nil
        )
      end

      def mark_as_cancelling(test_run_id)
        update(test_run_id, status: 'cancelling')
      end

      class Model < Sequel::Model(db)
        include ValidateRunnableReference

        one_to_many :results,
                    eager: [:messages, :requests],
                    class: 'Inferno::Repositories::Results::Model',
                    key: :test_run_id
        many_to_one :test_session, class: 'Inferno::Repositories::TestSessions::Model', key: :test_session_id

        def validate
          super
          if status.present? && !Entities::TestRun::STATUS_OPTIONS.include?(status) # rubocop:disable Style/GuardClause
            errors.add(:status, "'#{status}' is not valid")
          end
        end

        def before_create
          self.id = SecureRandom.uuid
          time = Time.now
          self.created_at ||= time
          self.updated_at ||= time
          super
        end
      end

      def active_test_run_for_session?(test_session_id)
        self.class::Model
          .where(test_session_id: test_session_id)
          .exclude(status: 'done')
          .count.positive?
      end
    end
  end
end
