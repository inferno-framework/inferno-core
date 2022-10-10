Inferno::Application.boot(:web) do |_app|
  init do
    require 'blueprinter'
    require 'hanami/router'
    require 'hanami/controller'
    require 'oj'

    Blueprinter.configure do |config|
      config.generator = Oj
    end
  end
end
