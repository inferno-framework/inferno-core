require 'sidekiq'

require_relative 'jobs/execute_test_run'
require_relative 'jobs/resume_test_run'
require_relative 'jobs/invoke_validator_session'

module Inferno
  module Jobs
    def self.perform(job_klass, *params, force_synchronous: false, tags: nil)
      tags = Array(tags).compact

      if force_synchronous || (Application['async_jobs'] == false)
        job_klass.new.perform(*params)
      elsif tags.any?
        job_klass.set(tags:).perform_async(*params)
      else
        job_klass.perform_async(*params)
      end
    end
  end
end
