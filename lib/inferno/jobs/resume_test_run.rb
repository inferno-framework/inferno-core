module Inferno
  module Jobs
    class ResumeTestRun
      include Sidekiq::Worker

      # Retrying would rerun the test that was in progress, resending its
      # requests, so surface failures instead.
      sidekiq_options retry: false

      def perform(test_run_id)
        test_run = Inferno::Repositories::TestRuns.new.find(test_run_id)
        test_session = Inferno::Repositories::TestSessions.new.find(test_run.test_session_id)

        TestRunner.new(test_session:, test_run:, resume: true).start
      end
    end
  end
end
