require 'sequel'
require 'erb'

Inferno::Application.boot(:db) do
  init do
    use :logging

    require 'yaml'

    Sequel::Model.plugin :json_serializer

    config_path = File.expand_path('database.yml', File.join(Dir.pwd, 'config'))
    config_contents = ERB.new(File.read(config_path)).result
    config = YAML.safe_load(config_contents)[ENV['APP_ENV']]
      .merge(logger: Inferno::Application['logger'])
    connection_attempts_remaining = ENV.fetch('MAX_DB_CONNECTION_ATTEMPTS', '10').to_i
    connection_retry_delay = ENV.fetch('DB_CONNECTION_RETRY_DELAY', '5').to_i
    connection = nil
    loop do
      connection = Sequel.connect(config)
      break
    rescue StandardError => e
      connection_attempts_remaining -= 1
      if connection_attempts_remaining.positive?
        Inferno::Application['logger'].error("Unable to connect to database: #{e.message}")
        Inferno::Application['logger'].error("#{connection_attempts_remaining} connection attempts remaining.")
        sleep connection_retry_delay
        next
      end
      raise
    end
    connection.sql_log_level = :debug

    register('db.config', config)
    register('db.connection', connection)
  end

  start do
    Sequel.extension :migration
  end
end
