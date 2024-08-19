Inferno::Application.register_provider(:cli) do
  prepare do
    target_container.start :logging

    require 'oj'
    require 'blueprinter'

    Blueprinter.configure do |config|
      config.generator = Oj
    end

    target_container.start :suites

    # This line is required to bypass the NO_DB env variable and load all repositories
    # but the NO_DB env variable itself is required to bypass specific Inferno boot bugs
    Dir.glob('../../../repositories/*.rb').each do |repository|
      require_relative repository
      puts "Require'd #{repository}"
    end
  end
end
