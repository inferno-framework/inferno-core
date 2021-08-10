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

    register('db.config', config)
    register('db.connection', connection)
  end

  start do
    Sequel.extension :migration
    db = Inferno::Application['db.connection']
    migration_path = File.join(Inferno::Application.root, 'lib', 'inferno', 'db', 'migrations')
    Sequel::Migrator.run(db, migration_path)

    if ENV['APP_ENV'] == 'development'
      schema_path = File.join(Inferno::Application.root, 'lib', 'inferno', 'db', 'schema.rb')
      db.extension :schema_dumper
      File.open(schema_path, 'w') { |f| f.print(db.dump_schema_migration) }
    end
  end
end
