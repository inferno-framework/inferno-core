module Inferno
  module Utils
    class Migration
      def run
        db = Inferno::Application['db.connection']
        migration_path = File.join(Inferno::Application.root, 'lib', 'inferno', 'db', 'migrations')
        Sequel::Migrator.run(db, migration_path)

        if ENV['APP_ENV'] == 'development' # rubocop:disable Style/GuardClause
          schema_path = File.join(Inferno::Application.root, 'lib', 'inferno', 'db', 'schema.rb')
          db.extension :schema_dumper
          File.open(schema_path, 'w') { |f| f.print(db.dump_schema_migration) }
        end
      end
    end
  end
end
