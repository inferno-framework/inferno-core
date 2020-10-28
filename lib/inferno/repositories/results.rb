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

      def json_serializer_options
        {
          include: {
            messages: {},
            requests: {
              include: { headers: {} },
              only: Entities::Request::SUMMARY_FIELDS
            }
          }
        }
      end

      class Model < Sequel::Model(db)
        include ValidateRunnableReference

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
      end
    end
  end
end
