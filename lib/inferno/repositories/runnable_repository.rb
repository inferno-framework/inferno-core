require_relative 'in_memory_repository'

module Inferno
  module Repositories
    class RunnableRepository < InMemoryRepository
      def insert(entity)
        raise Exceptions::DuplicateEntityIdException, entity.id if exists?(entity.id)
        # Safety check to prevent rare database_id collisions from overwriting entries
        if exists?(entity.database_id) && entity.database_id.to_s != entity.id.to_s
          raise Exceptions::DuplicateEntityIdException, "database_id: `#{entity.database_id}`"
        end

        all << entity
        all_by_id[entity.id.to_s] = entity
        all_by_id[entity.database_id.to_s] = entity unless entity.database_id.to_s == entity.id.to_s

        entity
      end

      def remove(entity)
        super

        all_by_id.delete(entity.database_id.to_s) unless entity.database_id.to_s == entity.id.to_s
      end
    end
  end
end
