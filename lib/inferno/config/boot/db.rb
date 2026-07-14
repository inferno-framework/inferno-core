require 'sequel'
require 'erb'

Inferno::Application.register_provider(:db) do
  prepare do
    target_container.start :logging

    require 'yaml'

    Sequel::Model.plugin :json_serializer

    config_path = File.expand_path('database.yml', File.join(Dir.pwd, 'config'))
    config_contents = ERB.new(File.read(config_path)).result
    config = YAML.safe_load(config_contents)[ENV.fetch('APP_ENV', nil)]
      .merge(logger: Inferno::Application['logger'])

    if config['adapter'] == 'sqlite'
      # The web and worker processes each hold their own pool of connections to the
      # same sqlite file, so writes from one process can easily collide with reads
      # or writes from another. WAL mode lets readers proceed without blocking on a
      # concurrent writer, and a longer busy_timeout gives a blocked writer more
      # room to wait its turn instead of immediately raising SQLITE_BUSY.
      connect_sqls = ["PRAGMA busy_timeout = #{ENV.fetch('DB_BUSY_TIMEOUT_MS', '15000')}"]
      connect_sqls << 'PRAGMA journal_mode = WAL' unless config['database'] == ':memory:'
      config['connect_sqls'] = connect_sqls
    end

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

    if config['adapter'] == 'sqlite'
      actual_journal_mode = connection.fetch('PRAGMA journal_mode').first[:journal_mode]
      Inferno::Application['logger'].info("sqlite journal_mode: #{actual_journal_mode}")
    end

    register('db.config', config)
    register('db.connection', connection)
  end

  start do
    Sequel.extension :migration
  end
end
