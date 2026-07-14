require 'sequel'
require 'erb'

module Inferno
  module Config
    module Boot
      # Extracted from the :db provider below so the sqlite-only branching can
      # be unit tested with plain config hashes/doubles, instead of requiring
      # a real postgres connection (which this project has no infrastructure
      # for) just to exercise the non-sqlite path.
      module Db
        module_function

        # The web and worker processes each hold their own pool of connections to the
        # same sqlite file, so writes from one process can easily collide with reads
        # or writes from another. WAL mode lets readers proceed without blocking on a
        # concurrent writer, and a longer busy_timeout gives a blocked writer more
        # room to wait its turn instead of immediately raising SQLITE_BUSY.
        #
        # If you change this, run `bundle exec rake db:check_concurrency` to verify
        # SQLITE_BUSY is still avoided under concurrent test-run writes and status
        # polling (see lib/inferno/utils/db_concurrency_check.rb for why that's a
        # rake task and not a spec).
        def configure_sqlite_pragmas!(config)
          return config unless config['adapter'] == 'sqlite'

          connect_sqls = ["PRAGMA busy_timeout = #{ENV.fetch('DB_BUSY_TIMEOUT_MS', '15000')}"]
          connect_sqls << 'PRAGMA journal_mode = WAL' unless config['database'] == ':memory:'
          config['connect_sqls'] = connect_sqls
          config
        end

        def log_sqlite_journal_mode(config, connection, logger)
          return unless config['adapter'] == 'sqlite'

          actual_journal_mode = connection.fetch('PRAGMA journal_mode').first[:journal_mode]
          logger.info("sqlite journal_mode: #{actual_journal_mode}")
        end
      end
    end
  end
end

Inferno::Application.register_provider(:db) do
  prepare do
    target_container.start :logging

    require 'yaml'

    Sequel::Model.plugin :json_serializer

    config_path = File.expand_path('database.yml', File.join(Dir.pwd, 'config'))
    config_contents = ERB.new(File.read(config_path)).result
    config = YAML.safe_load(config_contents)[ENV.fetch('APP_ENV', nil)]
      .merge(logger: Inferno::Application['logger'])

    Inferno::Config::Boot::Db.configure_sqlite_pragmas!(config)

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

    Inferno::Config::Boot::Db.log_sqlite_journal_mode(config, connection, Inferno::Application['logger'])

    register('db.config', config)
    register('db.connection', connection)
  end

  start do
    Sequel.extension :migration
  end
end
