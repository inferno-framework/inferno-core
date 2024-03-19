Inferno::Application.register_provider(:web) do |_app|
  prepare do
    require 'blueprinter'
    require 'hanami/router'
    require 'hanami/controller'
    require 'oj'

    Blueprinter.configure do |config|
      config.generator = Oj
    end

    require 'inferno/utils/middleware/request_logger'
    require 'inferno/utils/middleware/request_recorder'
    require 'inferno/apps/web/application'
  end
end
