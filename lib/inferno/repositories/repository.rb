module Inferno
  module Repositories
    # Base class for repositories. Subclass and override methods as
    # needed.
    #
    # @abstract
    class Repository
      extend Forwardable

      def_delegators 'self.class', :db, :table_name

      # Return the db connection for this repository.
      def self.db
        Application['db.connection'][table_name]
      end

      # Return the name of the database table for this repository. Override if
      # the table name is not the snake case version of the name of the
      # repository class.
      #
      # @return [String]
      def self.table_name
        name.demodulize.underscore.to_sym
      end

      # Return the name of the entity class which will be instantiated by a
      # repository. Override if the entity class name is not the singular
      # version of the repository name.
      #
      # @return [Class]
      def entity_class_name
        self.class.name.demodulize.singularize
      end

      # Return the class of the entity which will be instantiated by a
      # repository. Override if the entity class is not in the
      # `Inferno::Entities` namespace.
      #
      # @return [Class]
      def entity_class
        Entities.const_get(entity_class_name)
      end

      # Find a database record by id, and instantiate an entity from that
      # record.
      #
      # @param id [String]
      # @return [Inferno::Entities] an instance of the class returned by
      #   `#entity_class`
      def find(id)
        result = self.class::Model.find(id:)
        return result if result.nil?

        build_entity(result.to_hash)
      end

      def add_non_db_entities(hash)
        if hash.include? :test_id
          hash[:test] = Tests.new.find(hash[:test_id])
        elsif hash.include? :test_group_id
          hash[:test_group] = TestGroups.new.find(hash[:test_group_id])
        elsif hash.include? :test_suite_id
          hash[:test_suite] = TestSuites.new.find(hash[:test_suite_id])
        end
      end

      # Create a new record in the database.
      #
      # @param params [Hash]
      # @return [Inferno::Entities] an instance of the entity for this repo
      # @example
      #   repo = Inferno::Repositories::SomeEntities.new
      #   begin
      #     result = repo.create(key1: 'value1', key2: 'value2')
      #   rescue Sequel::ValidationFailed => e
      #     # handle error
      #   end
      def create(params)
        result = self.class::Model.create(db_params(params))
        build_entity(result.to_hash.merge(handle_non_db_params(params)))
      end

      # Update a record in the database.
      #
      # @param entity_id [String]
      # @param params [Hash]
      # @example
      #   repo = Inferno::Repositories::SomeEntities.new
      #   result = repo.update(id, key1: 'value1', key2: 'value2')
      def update(entity_id, params = {})
        self.class::Model
          .find(id: entity_id)
          .update(params.merge(updated_at: Time.now))
      end

      # Creates an instance of the entity associated with this repository.
      # Override if any special logic is required to create the entity.
      #
      # @param params [Hash]
      # @return [Object] an instance of `#entity_class`
      def build_entity(params)
        add_non_db_entities(params)
        entity_class.new(params)
      end

      def db_params(params)
        params.slice(*self.class::Model.columns)
      end

      def non_db_params(params)
        params.except(*self.class::Model.columns)
      end

      def handle_non_db_params(params)
        non_db_params(params)
      end
    end
  end
end
