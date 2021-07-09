module Inferno
  module Repositories
    class SessionData < Repository
      def save(params)
        name = params[:name].to_s.downcase
        test_session_id = params[:test_session_id]
        db
          .insert_conflict(
            target: :id,
            update: { value: params[:value] }
          ).insert(
            id: "#{test_session_id}_#{name}",
            name: name,
            value: params[:value],
            test_session_id: test_session_id
          )
      end

      def load(test_session_id:, name:)
        self.class::Model
          .find(test_session_id: test_session_id, name: name.to_s.downcase)
          &.value
      end

      class Model < Sequel::Model(db)
        many_to_one :test_session, class: 'Inferno::Repositories::TestSessions::Model', key: :test_session_id
      end
    end
  end
end
