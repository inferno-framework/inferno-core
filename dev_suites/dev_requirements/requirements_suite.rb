module RequirementsSuite
  class Suite < Inferno::TestSuite
    title 'Requirements Suite'
    id :ig_requirements
    description 'Suite Description'

    requirement_sets(
      {
        identifier: 'sample-criteria-proposal',
        actor: 'Client'
      }
    )

    group do
      title 'Goup 1'
      group do
        title 'Test Requirements 1 and 2'
        verifies_requirements 'sample-criteria-proposal@1', 'sample-criteria-proposal@2'

        test do
          title 'Requirement 1'
          run { pass }
        end

        test do
          title 'Requirement 2'
          run { pass }
        end

        test do
          title 'Requirement 5'
          verifies_requirements 'sample-criteria-proposal@5'
          optional
          run { pass }
        end
      end

      group do
        title 'Test Requirements 3 and 4'
        verifies_requirements 'sample-criteria-proposal@3', 'sample-criteria-proposal@4'

        test do
          title 'Requirement 3'
          run { pass }
        end

        test do
          title 'Requirement 4'
          run { pass }
        end
      end
    end

    group do
      title 'Test Requirements 6 and 7'
      verifies_requirements 'sample-criteria-proposal@6', 'sample-criteria-proposal@7'

      test do
        title 'Requirement 6'
        run { pass }
      end

      test do
        title 'Requirement 7'
        run { pass }
      end
    end
  end
end
