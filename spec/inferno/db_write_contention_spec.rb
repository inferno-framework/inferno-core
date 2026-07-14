require 'spec_helper'
require 'tmpdir'
require 'securerandom'

# These specs exercise real file-backed sqlite concurrency, which the rest of
# the suite cannot: the app's `test` environment uses `:memory:`
# (config/database.yml), and Sequel forces `max_connections = 1` for
# `:memory:` databases, because separate connections to `:memory:` don't
# share data. That means the ordinary spec suite always talks to sqlite
# through a single physical connection and can never reproduce SQLITE_BUSY.
#
# Each example here opens its own real temp-file sqlite database with a real
# multi-connection pool and the same busy_timeout/WAL settings used in
# lib/inferno/config/boot/db.rb, to approximate how the web and worker
# processes actually contend for the same sqlite file in production.
# rubocop:disable RSpec/DescribeClass
RSpec.describe 'sqlite write contention' do
  # rubocop:enable RSpec/DescribeClass
  # Chosen to reliably reproduce SQLITE_BUSY on this machine when WAL/
  # busy_timeout/transaction-wrapping are reverted (verified: ~350 busy
  # errors without the fix, 0 with it, across repeated runs). Lighter loads
  # didn't generate enough real contention to distinguish the two.
  let(:writer_threads) { 16 }
  let(:cascades_per_writer) { 40 }
  let(:reader_threads) { 8 }
  let(:max_connections) { 30 }

  let(:tmp_dir) { Dir.mktmpdir }
  let(:db_path) { File.join(tmp_dir, 'contention.db') }

  after { FileUtils.remove_entry(tmp_dir) }

  def connect_db
    connect_sqls = ["PRAGMA busy_timeout = #{ENV.fetch('DB_BUSY_TIMEOUT_MS', '15000')}", 'PRAGMA journal_mode = WAL']
    Sequel.connect(adapter: 'sqlite', database: db_path, max_connections:, connect_sqls:)
  end

  def build_schema(db)
    db.create_table(:results) do
      primary_key :id
      column :test_id, String
      column :result, String
    end
    db.create_table(:requests) do
      primary_key :id
      foreign_key :result_id, :results
      column :verb, String
    end
    db.create_table(:headers) do
      primary_key :id
      foreign_key :request_id, :requests
      column :name, String
      column :value, String
    end
  end

  def build_models(db)
    [
      Class.new(Sequel::Model(db[:results])),
      Class.new(Sequel::Model(db[:requests])),
      Class.new(Sequel::Model(db[:headers]))
    ]
  end

  # Mirrors the shape of the real write cascade in
  # Inferno::Repositories::Results#create (called from
  # TestRunner#persist_result after every test/group/parent roll-up): one
  # result, several requests, several headers per request. Each Model.create
  # is a separate sqlite transaction by default (Sequel::Model.use_transactions
  # defaults to true), unless the caller wraps them in one, exactly like
  # TestRunner#persist_result now does.
  def create_cascade(result_class, request_class, header_class)
    result = result_class.create(test_id: SecureRandom.uuid, result: 'pass')
    3.times do
      request = request_class.create(result_id: result.id, verb: 'GET')
      2.times do |i|
        header_class.create(request_id: request.id, name: "Header-#{i}", value: SecureRandom.hex(8))
      end
    end
    result
  end

  def persist_cascade(db, result_class, request_class, header_class)
    db.transaction { create_cascade(result_class, request_class, header_class) }
  end

  def busy_exception?(error)
    error.is_a?(Sequel::DatabaseError) && error.message =~ /database is locked|SQLITE_BUSY/i
  end

  it 'persists concurrent test-result cascades without raising SQLITE_BUSY under continuous concurrent reads' do
    db = connect_db
    build_schema(db)
    result_class, request_class, header_class = build_models(db)

    errors = []
    errors_mutex = Mutex.new
    stop_reading = false

    writers = Array.new(writer_threads) do
      Thread.new do
        cascades_per_writer.times { persist_cascade(db, result_class, request_class, header_class) }
      rescue StandardError => e
        errors_mutex.synchronize { errors << e }
      end
    end

    # Simulates the CLI/docker execution script's status polling, which reads
    # results from a different connection while the worker writes new ones.
    readers = Array.new(reader_threads) do
      Thread.new do
        until stop_reading
          result_class.order(Sequel.desc(:id)).limit(1).all
          request_class.order(Sequel.desc(:id)).limit(1).all
        end
      rescue StandardError => e
        errors_mutex.synchronize { errors << e }
      end
    end

    writers.each(&:join)
    stop_reading = true
    readers.each(&:join)
    db.disconnect

    busy_errors = errors.select { |e| busy_exception?(e) }
    other_errors = errors - busy_errors

    expect(other_errors.map(&:message)).to be_empty
    expect(busy_errors.map(&:message)).to be_empty
    expect(result_class.count).to eq(writer_threads * cascades_per_writer)
  end
end
