require 'sidekiq'

require_relative 'jobs/execute_test_run'

module Inferno
  module Jobs
    def self.perform(job_klass, *params)
      if ENV['SYNCHRONOUS_JOBS'] == 'true'
        job_klass.new.perform(*params)
      else
        job_klass.perform_async(*params)
      end
    end
  end
end
