module Inferno
  module Jobs
    include Sidekiq::Worker

    def perform(test_session_id, test_run_id)
      test_session = Inferno::Repositories::TestSessions.find(test_session_id)
      test_run = Inferno::Repositories::TestRuns.find(test_run_id)

      TestRunner.new(test_session: test_session, test_run: test_run).start
    end
  end
end
