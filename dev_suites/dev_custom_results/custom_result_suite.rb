module CustomResult
  class PassingCustomResultGroup < Inferno::TestGroup
    id :passing_custom_result_group
    title 'Passing Group'
    description 'Criteria: Passes if test 1 passes, or test 2 and test 3 pass'

    customize_passing_result do |results|
      test1_result = results[tests.first.id].result
      test2_result = results[tests[1].id].result
      test3_result = results[tests.last.id].result

      test1_result == 'pass' || (test2_result == 'pass' && test3_result == 'pass')
    end

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
  end

  class NonPassingCustomResultGroup < Inferno::TestGroup
    id :non_passing_custom_result_group
    title 'Non passing Group'
    description 'Criteria: Passes if test 1 passes, or test 2 and test 3 pass'

    optional

    customize_passing_result do |results|
      test1_result = results[tests.first.id].result
      test2_result = results[tests[1].id].result
      test3_result = results[tests.last.id].result

      test1_result == 'pass' || (test2_result == 'pass' && test3_result == 'pass')
    end

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
  end

  class PassingCustomResultGroupWithNestedGroups < Inferno::TestGroup
    id :passing_custom_result_group_with_nested_groups
    title 'Passing Group with Nested Groups'
    description 'Criteria: Passes if inner group 1 passes, or inner group 2 and inner group 3 pass'

    optional

    customize_passing_result do |results|
      group1_result = results[groups.first.id].result
      group2_result = results[groups[1].id].result
      group3_result = results[groups.last.id].result

      group1_result == 'pass' || (group2_result == 'pass' && group3_result == 'pass')
    end

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
  end

  class Suite < Inferno::TestSuite
    id :custom_result_suite
    title 'Custom Result Suite'
    description 'Criteria: Passes if `Passing Group` passes and any of the other groups passes.'

    customize_passing_result do |results|
      puts "RESULTS SIZE: #{results.results.size}"
      group1_result = results[:passing_custom_result_group]
      other_groups_pass = results.any? do |result|
        result.test_group_id != group1_result.test_group_id && result.result == 'pass'
      end
      group1_result.result == 'pass' && other_groups_pass
    end

    group from: :passing_custom_result_group
    group from: :non_passing_custom_result_group
    group from: :passing_custom_result_group_with_nested_groups
  end
end
