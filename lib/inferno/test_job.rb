require 'sidekiq'

module Inferno
  class TestJob
    include Sidekiq::Worker

    def perform(n = 2)
      sleep n
      puts 'All done'
    end
  end
end
