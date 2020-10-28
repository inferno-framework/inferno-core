require_relative 'in_memory_repository'

module Inferno
  module Repositories
    # Repository that deals with persistence for the `Test` entity.
    class Tests < InMemoryRepository
    end
  end
end
