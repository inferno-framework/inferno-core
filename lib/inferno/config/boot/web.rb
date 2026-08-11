Inferno::Application.register_provider(:web) do |_app|
  prepare do
    require 'blueprinter'
    require 'oj'

    Blueprinter.configure do |config|
      config.generator = Oj
      # Oj >= 3.17 no longer honors ActiveSupport's Time#to_json, which
      # dropped sub-second precision from serialized timestamps. Clients
      # order results by these strings, so keep millisecond precision.
      config.datetime_format = '%FT%T.%L%:z'
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
