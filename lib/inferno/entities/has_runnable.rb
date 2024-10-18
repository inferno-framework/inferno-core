module Inferno
  module Entities
    module HasRunnable
      # Returns the Test, TestGroup, or TestSuite associated with this entity
      #
      # @return [Inferno::Entities::Test, Inferno::Entities::TestGroup, Inferno::Entities::TestSuite]
      def runnable
        return @runnable if @runnable

        @runnable = test || test_group || test_suite || load_runnable
      end

      private

      def load_runnable
        if test_id.present?
          @test = Inferno::Repositories::Tests.new.find(test_id)
        elsif test_group_id.present?
          @test_group = Inferno::Repositories::TestGroups.new.find(test_group_id)
        elsif test_suite_id.present?
          @test_suite = Inferno::Repositories::TestSuites.new.find(test_suite_id)
        end
      end
    end
  end
end
