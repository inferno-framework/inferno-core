module OptionsSuite
  class V1Group < Inferno::TestGroup
    title 'V1 Group'
    id :v1_group
  end

  class V2Group < Inferno::TestGroup
    title 'V2 Group'
    id :v2_group
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

    group from: :v1_group,
          when: { ig_version: '1' }

    group from: :v2_group,
          when: { ig_version: '2' }
  end
end
