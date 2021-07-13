module Inferno
  module Jobs
    class ExecuteTestRun
      include Sidekiq::Worker

      def perform(test_session_id:, test_run_id:)
        test_session = Inferno::Repositories::TestSessions.new.find(test_session_id)
        test_run = Inferno::Repositories::TestRuns.new.find(test_run_id)

        TestRunner.new(test_session: test_session, test_run: test_run).start
      end
    end
  end
end
