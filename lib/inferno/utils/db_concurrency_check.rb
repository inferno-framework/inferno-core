require 'sequel'
require 'sqlite3'
require 'tmpdir'
require 'securerandom'

module Inferno
  module Utils
    # Verifies that the sqlite WAL/busy_timeout/transaction-wrapping in
    # lib/inferno/config/boot/db.rb and TestRunner#persist_result actually
    # prevent SQLITE_BUSY under concurrent test-run writes and status-polling
    # reads against a shared sqlite file.
    #
    # This is deliberately NOT an rspec example. It's a real-time concurrency
    # measurement, and a hardcoded load level that reliably reproduces (or
    # avoids) SQLITE_BUSY on one machine does not transfer to others: a load
    # level tuned to fail reliably without the fix and pass reliably with it,
    # verified repeatedly on one machine, failed consistently in GitHub
    # Actions and on another local machine. Rather than assert against a
    # fixed load level, this calibrates to whatever machine it runs on: it
    # escalates the write volume until it can demonstrate the *unprotected*
    # configuration actually hits SQLITE_BUSY, then checks whether the
    # *protected* configuration avoids it under that same, machine-calibrated
    # load.
    #
    # Run manually with `bundle exec rake db:check_concurrency` after changing
    # the persistence/locking behavior in the files above. It isn't part of
    # the default test suite because it's a real-time measurement, not a
    # deterministic assertion, and shouldn't gate CI.
    module DbConcurrencyCheck
      WRITER_THREADS = 5
      READER_THREADS = 3
      READER_POLL_INTERVAL = 0.2
      MAX_CONNECTIONS = 15
      MAX_CASCADES_PER_WRITER = 5000

      module_function

      def run
        cascades = 10
        baseline_errors = []

        loop do
          baseline_errors = measure(protected: false, cascades_per_writer: cascades)
          break if baseline_errors.any? || cascades > MAX_CASCADES_PER_WRITER

          cascades *= 2
        end

        if baseline_errors.empty?
          puts "INCONCLUSIVE: could not reproduce SQLITE_BUSY even at #{cascades} cascades/writer on this machine."
          return true
        end

        puts "Reproduced #{baseline_errors.size} SQLITE_BUSY error(s) without WAL/busy_timeout/transaction-" \
             "wrapping at #{cascades} cascades/writer (#{WRITER_THREADS} writers, #{READER_THREADS} readers " \
             "polling every #{READER_POLL_INTERVAL}s)."

        protected_errors = measure(protected: true, cascades_per_writer: cascades)

        if protected_errors.empty?
          puts 'PASS: the current fix avoided SQLITE_BUSY under the same load that reproduced it above.'
          true
        else
          puts "FAIL: the current fix still hit #{protected_errors.size} SQLITE_BUSY error(s) under the same load:"
          puts protected_errors.first.message
          false
        end
      end

      def measure(protected:, cascades_per_writer:)
        Dir.mktmpdir do |dir|
          db = connect(File.join(dir, 'contention.db'), protected:)
          result_class, request_class, header_class = build_schema_and_models(db)
          errors = []
          mutex = Mutex.new
          stop_reading = false

          writers = Array.new(WRITER_THREADS) do
            Thread.new do
              cascades_per_writer.times do
                persist_cascade(db, result_class, request_class, header_class, protected:)
              rescue StandardError => e
                mutex.synchronize { errors << e }
              end
            end
          end

          readers = Array.new(READER_THREADS) do
            Thread.new { poll_until(-> { stop_reading }, result_class, request_class, errors, mutex) }
          end

          writers.each(&:join)
          stop_reading = true
          readers.each(&:join)
          db.disconnect

          errors.select { |e| e.is_a?(Sequel::DatabaseError) && e.message =~ /database is locked|SQLITE_BUSY/i }
        end
      end

      def connect(db_path, protected:)
        connect_sqls =
          if protected
            ["PRAGMA busy_timeout = #{ENV.fetch('DB_BUSY_TIMEOUT_MS', '15000')}", 'PRAGMA journal_mode = WAL']
          else
            ['PRAGMA busy_timeout = 0']
          end
        Sequel.connect(adapter: 'sqlite', database: db_path, max_connections: MAX_CONNECTIONS, connect_sqls:)
      end

      def persist_cascade(db, result_class, request_class, header_class, protected:)
        if protected
          db.transaction { create_cascade(result_class, request_class, header_class) }
        else
          create_cascade(result_class, request_class, header_class)
        end
      end

      def poll_until(stop, result_class, request_class, errors, mutex)
        until stop.call
          result_class.order(Sequel.desc(:id)).limit(1).all
          request_class.order(Sequel.desc(:id)).limit(1).all
          sleep(READER_POLL_INTERVAL)
        end
      rescue StandardError => e
        mutex.synchronize { errors << e }
      end

      def build_schema_and_models(db)
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

        [
          Class.new(Sequel::Model(db[:results])),
          Class.new(Sequel::Model(db[:requests])),
          Class.new(Sequel::Model(db[:headers]))
        ]
      end

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
    end
  end
end
