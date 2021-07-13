require 'sidekiq'

module Inferno
  module Jobs
    def self.perform(job_klass, **params)
      job_klass.new.perform(params)
    end
  end
end
