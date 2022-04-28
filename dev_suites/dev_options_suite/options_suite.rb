module OptionsSuite
  class V1Group < Inferno::TestGroup
    title 'V1 Group'
    id :v1_group

    test do
      title 'V1 Test'
      id :v1_test

      run { pass }
    end
  end

  class V2Group < Inferno::TestGroup
    title 'V2 Group'
    id :v2_group

    test do
      title 'V2 Test'
      id :v2_test

      run { pass }
    end
  end

  class AllVersionsGroup < Inferno::TestGroup
    title 'All Versions Group'
    id :all_versions_group

    test do
      title 'All Versions Test'
      id :all_versions_test

      run { pass }
    end
  end

  class Suite < Inferno::TestSuite
    title 'Options Suite'
    id :options

    suite_option :ig_version,
                 title: 'IG Version',
                 description: 'Which IG Version should be used',
                 list_options: [
                   {
                     label: 'v1',
                     value: '1'
                   },
                   {
                     label: 'v2',
                     value: '2'
                   }
                 ]

    group from: :all_versions_group

    group from: :v1_group,
          when: { ig_version: '1' }

    group from: :v2_group,
          when: { ig_version: '2' }
  end
end
