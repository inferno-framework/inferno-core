module CustomResult
  class PassingCustomResultGroup < Inferno::TestGroup
    id :passing_custom_result_group
    title 'Passing Group'
    description 'Criteria: Passes if test 1 passes, or test 2 and test 3 pass'

    test 'Test 1: passing' do
      run { assert true }
    end

    test 'Test 2: passing' do
      optional

      run { assert true }
    end

    test 'Test 3: failing' do
      optional

      run { assert false }
    end

    run do
      test1_result = child_results[tests.first.id].result
      pass_if test1_result == 'pass', 'Test 1 passed'

      test2_result = child_results[tests[1].id].result
      test3_result = child_results[tests.last.id].result

      assert test2_result == 'pass' && test3_result == 'pass', 'Either test 1, or test 2 and test 3  must pass'
    end
  end

  class NonPassingCustomResultGroup < Inferno::TestGroup
    id :non_passing_custom_result_group
    title 'Non passing Group'
    description 'Criteria: Passes if test 1 passes, or test 2 and test 3 pass'

    optional

    test 'Test 1: failing' do
      run { assert false }
    end

    test 'Test 2: passing' do
      optional

      run { assert true }
    end

    test 'Test 3: skipping' do
      optional

      run { skip }
    end

    run do
      test1_result = child_results[tests.first.id].result
      pass_if test1_result == 'pass', 'Test 1 passed'
      info 'Test 1 did not pass'

      test2_result = child_results[tests[1].id].result
      test3_result = child_results[tests.last.id].result

      assert test2_result == 'pass' && test3_result == 'pass', 'Either test 1, or test 2 and test 3 must pass'
    end
  end

  class PassingCustomResultGroupWithNestedGroups < Inferno::TestGroup
    id :passing_custom_result_group_with_nested_groups
    title 'Passing Group with Nested Groups'
    description 'Criteria: Passes if inner group 1 passes, or inner group 2 and inner group 3 pass'

    optional

    group 'Inner Group 1: failing' do
      test do
        run { assert false }
      end
    end

    group 'Inner Group 2: passing' do
      optional

      test do
        run { assert true }
      end
    end

    group 'Inner Group 3: passing' do
      optional

      test do
        run { assert true }
      end
    end

    run do
      group1_result = child_results[groups.first.id].result
      pass_if group1_result == 'pass', 'Inner Group 1 passed.'
      add_message('info', 'Inner Group 1 did not pass.')

      group2_result = child_results[groups[1].id].result
      group3_result = child_results[groups.last.id].result

      assert group2_result == 'pass' && group3_result == 'pass',
             'Either inner group 1, or inner group 2 and inner group 3 must pass'
    end
  end

  class Suite < Inferno::TestSuite
    id :custom_result_suite
    title 'Custom Result Suite'
    description 'Criteria: Passes if `Passing Group` passes and any of the other groups passes.'

    group from: :passing_custom_result_group
    group from: :non_passing_custom_result_group
    group from: :passing_custom_result_group_with_nested_groups

    run do
      group1_result = child_results[:passing_custom_result_group]
      other_groups_pass = child_results.any? do |result|
        result.test_group_id != group1_result.test_group_id && result.result == 'pass'
      end
      assert group1_result.result == 'pass' && other_groups_pass,
             '`Passing Group` and any of the other groups must pass.'
    end
  end
end
