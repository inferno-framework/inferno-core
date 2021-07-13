require 'sidekiq'

require_relative 'jobs/execute_test_run'

module Inferno
  module Jobs
    def self.perform(job_klass, *params)
      if Application['async_jobs']
        job_klass.perform_async(*params)
      else
        job_klass.new.perform(*params)
      end
    end
  end
end
