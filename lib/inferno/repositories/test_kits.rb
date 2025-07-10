require_relative 'in_memory_repository'

module Inferno
  module Repositories
    # Repository that deals with persistence for the `TestKit` entity.
    class TestKits < InMemoryRepository
      def local_test_kit
        local_base_path = File.join(Dir.pwd, 'lib')

        self.class.all.find do |test_kit|
          Object.const_source_location(test_kit.name).first.start_with? local_base_path
        end
      end
    end
  end
end
