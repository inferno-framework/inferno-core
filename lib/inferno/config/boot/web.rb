Inferno::Application.register_provider(:web) do |_app|
  prepare do
    require 'blueprinter'
    require 'oj'

    Blueprinter.configure do |config|
      config.generator = Oj
    end

    # Workers aren't connected to a web server, so they shouldn't be hosting
    # routes
    next if Sidekiq.server?

    require 'hanami/router'
    require 'hanami/controller'
    require 'inferno/utils/middleware/request_logger'
    require 'inferno/apps/web/application'
  end
end
