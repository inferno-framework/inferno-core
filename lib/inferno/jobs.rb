require 'sidekiq'

require_relative 'jobs/execute_test_run'
require_relative 'jobs/resume_test_run'
require_relative 'jobs/invoke_validator_session'

module Inferno
  module Jobs
    def self.perform(job_klass, *params, force_synchronous: false)
      if force_synchronous || (Application['async_jobs'] === false)
        job_klass.new.perform(*params)
      else
        job_klass.perform_async(*params)
      end
    end
  end
end
