require 'forwardable'
require_relative '../exceptions'

module Inferno
  module Repositories
    class InMemoryRepository
      extend Forwardable

      def_delegators 'self.class', :all, :all_by_id

      def insert(entity)
        raise Exceptions::DuplicateEntityIdException, entity.id if exists?(entity.id)

        all << entity
        all_by_id[entity.id.to_s] = entity
        entity
      end

      def find(id)
        all_by_id[id.to_s]
      end

      def exists?(id)
        all_by_id.key?(id.to_s)
      end

      class << self
        def all
          @all ||= []
        end

        # @private
        def all_by_id
          @all_by_id ||= {}
        end
      end
    end
  end
end
