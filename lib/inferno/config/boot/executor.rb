Inferno::Application.register_provider(:executor) do
  prepare do
    target_container.start :logging

    require 'oj'
    require 'blueprinter'

    Blueprinter.configure do |config|
      config.generator = Oj
    end

    target_container.start :suites
  end
end
