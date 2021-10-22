require 'sequel'

Inferno::Application.boot(:db) do
  init do
    use :logging

    require 'yaml'

    Sequel::Model.plugin :json_serializer

    config_path = File.expand_path('database.yml', File.join(Dir.pwd, 'config'))
    config = YAML.load_file(config_path)[ENV['APP_ENV']]
      .merge(logger: Inferno::Application['logger'])
    connection = Sequel.connect(config)
    connection.sql_log_level = :debug

    register('db.config', config)
    register('db.connection', connection)
  end

  start do
    Sequel.extension :migration
  end
end
