require 'sidekiq'

Inferno::Application.register_provider(:sidekiq) do
  prepare do
    if Inferno::Application['async_jobs']
      Sidekiq.configure_server do |config|
        config.redis = { url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0') }

        config.capsule('validator_sessions') do |cap|
          cap.concurrency = ENV.fetch('VALIDATOR_SESSIONS_CONCURRENCY', '1').to_i
          cap.queues = ['validator_sessions']
        end
      end
    end
  end
end
