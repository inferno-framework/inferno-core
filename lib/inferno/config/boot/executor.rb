Inferno::Application.register_provider(:executor) do
  prepare do
    target_container.start :logging

    require 'oj'
    require 'blueprinter'

    Blueprinter.configure do |config|
      config.generator = Oj
      # Oj >= 3.17 no longer honors ActiveSupport's Time#to_json, which
      # dropped sub-second precision from serialized timestamps. Clients
      # order results by these strings, so keep millisecond precision.
      config.datetime_format = '%FT%T.%L%:z'
    end

    target_container.start :suites
    target_container.start :presets
  end
end
