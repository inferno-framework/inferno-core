module Inferno
  module Jobs
    class ResumeTestRun
      include Sidekiq::Worker

      def perform(test_run_id)
        test_run = Inferno::Repositories::TestRuns.new.find(test_run_id)
        test_session = Inferno::Repositories::TestSessions.new.find(test_run.test_session_id)

        sleep 5
        TestRunner.new(test_session: test_session, test_run: test_run, resume: true).start
      end
    end
  end
end
