require 'sidekiq'

Inferno::Application.boot(:sidekiq) do
  init do
    unless ENV['SYNCHRONOUS_JOBS'] == 'true'
      Sidekiq.configure_server do |config|
        config.redis = { url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/0') }
      end
    end
  end
end
