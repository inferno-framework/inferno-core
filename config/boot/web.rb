Inferno::Application.boot(:web) do |_app|
  init do
    require 'blueprinter'
    require 'hanami-router'
    require 'hanami-controller'
    require 'oj'

    Hanami::Controller.configure do
      default_request_format :json
      default_response_format :json
    end

    Blueprinter.configure do |config|
      config.generator = Oj
    end
  end
end
