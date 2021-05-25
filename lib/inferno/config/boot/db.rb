Inferno::Application.boot(:db) do
  init do
    use :logging

    require 'yaml'

    Sequel::Model.plugin :json_serializer

    config_path = File.expand_path('database.yml', File.join(Inferno::Application.root, 'lib', 'inferno', 'config'))
    config = YAML.load_file(config_path)[ENV['APP_ENV']]
      .merge(logger: Inferno::Application['logger'])
    connection = Sequel.connect(config)

    register('db.config', config)
    register('db.connection', connection)
  end

  start do
    Sequel.extension :migration
    migration_path = File.join(Inferno::Application.root, 'lib', 'inferno', 'db', 'migrations')
    Sequel::Migrator.run(Inferno::Application['db.connection'], migration_path)
  end
end
