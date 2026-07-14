require 'spec_helper'

RSpec.describe Inferno::Config::Boot::Db do
  describe '.configure_sqlite_pragmas!' do
    context 'when the adapter is sqlite' do
      it 'sets busy_timeout and journal_mode=WAL for a file-backed database' do
        config = { 'adapter' => 'sqlite', 'database' => 'data/inferno_development.db' }

        described_class.configure_sqlite_pragmas!(config)

        expect(config['connect_sqls']).to include(a_string_matching(/PRAGMA busy_timeout = \d+/))
        expect(config['connect_sqls']).to include('PRAGMA journal_mode = WAL')
      end

      it 'respects DB_BUSY_TIMEOUT_MS when set' do
        config = { 'adapter' => 'sqlite', 'database' => 'data/inferno_development.db' }
        original = ENV.fetch('DB_BUSY_TIMEOUT_MS', nil)
        begin
          ENV['DB_BUSY_TIMEOUT_MS'] = '42'
          described_class.configure_sqlite_pragmas!(config)
        ensure
          ENV['DB_BUSY_TIMEOUT_MS'] = original
        end

        expect(config['connect_sqls']).to include('PRAGMA busy_timeout = 42')
      end

      it 'does not enable WAL for an in-memory database' do
        config = { 'adapter' => 'sqlite', 'database' => ':memory:' }

        described_class.configure_sqlite_pragmas!(config)

        expect(config['connect_sqls']).to include(a_string_matching(/busy_timeout/))
        expect(config['connect_sqls']).to_not include('PRAGMA journal_mode = WAL')
      end
    end

    context 'when the adapter is not sqlite' do
      it 'leaves the config untouched' do
        config = { 'adapter' => 'postgres', 'database' => 'inferno_development' }

        described_class.configure_sqlite_pragmas!(config)

        expect(config).to_not have_key('connect_sqls')
      end
    end
  end

  describe '.log_sqlite_journal_mode' do
    context 'when the adapter is sqlite' do
      it 'logs the journal_mode reported by the connection' do
        config = { 'adapter' => 'sqlite' }
        connection = instance_spy(Sequel::Database)
        dataset = instance_double(Sequel::Dataset)
        logger = instance_spy(Logger)

        allow(connection).to receive(:fetch).with('PRAGMA journal_mode').and_return(dataset)
        allow(dataset).to receive(:first).and_return(journal_mode: 'wal')

        described_class.log_sqlite_journal_mode(config, connection, logger)

        expect(logger).to have_received(:info).with('sqlite journal_mode: wal')
      end
    end

    context 'when the adapter is not sqlite' do
      it 'does not query the connection or log anything' do
        config = { 'adapter' => 'postgres' }
        connection = instance_spy(Sequel::Database)
        logger = instance_spy(Logger)

        described_class.log_sqlite_journal_mode(config, connection, logger)

        expect(connection).to_not have_received(:fetch)
        expect(logger).to_not have_received(:info)
      end
    end
  end
end
