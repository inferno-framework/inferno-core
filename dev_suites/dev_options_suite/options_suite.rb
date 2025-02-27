module OptionsSuite
  class V1Group < Inferno::TestGroup
    title 'V1 Group'
    id :v1_group

    input :v1_input

    test do
      title 'V1 Test'
      id :v1_test

      run do
        assert suite_options[:ig_version] == '1'
      end
    end
  end

  class V2Group < Inferno::TestGroup
    title 'V2 Group'
    id :v2_group

    input :v2_input

    test do
      title 'V2 Test 1'
      id :v2_test1

      run do
        assert suite_options[:ig_version] == '2'
      end
    end

    test do
      title 'V2 Test 2'
      id :v2_test2

      run do
        assert suite_options[:ig_version] == '2'
      end
    end
  end

  class AllVersionsGroup < Inferno::TestGroup
    title 'All Versions Group'
    id :all_versions_group

    input :all_versions_input

    test do
      title 'All Versions Test 1'
      id :all_versions_test1

      run { pass }
    end

    test do
      title 'All Versions Test 2'
      id :all_versions_test2

      required_suite_options ig_version: '1'

      run { pass }
    end

    test do
      title 'All Versions Test 3'
      id :all_versions_test3

      required_suite_options ig_version: '2'

      run { pass }
    end
  end

  class Suite < Inferno::TestSuite
    title 'Options Suite'
    id :options
    description %(
      Suite description should go here

      Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
      tempor incididunt ut labore et dolore magna aliqua.

      Feugiat in ante metus dictum. Dignissim cras tincidunt lobortis feugiat.
      Consequat mauris nunc congue nisi vitae suscipit tellus mauris. Venenatis
      a condimentum vitae sapien pellentesque habitant morbi tristique senectus.

      Faucibus scelerisque eleifend donec pretium vulputate sapien nec sagittis
      aliquam. Nulla facilisi nullam vehicula ipsum a. Donec enim diam vulputate
      ut. Ornare arcu dui vivamus arcu felis bibendum ut tristique et. Malesuada
      fames ac turpis egestas maecenas pharetra convallis posuere morbi.
    )
    suite_summary %(
      Suite options summary should go here

      Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
      tempor incididunt ut labore et dolore magna aliqua.

      Feugiat in ante metus dictum. Dignissim cras tincidunt lobortis feugiat.
      Consequat mauris nunc congue nisi vitae suscipit tellus mauris. Venenatis
      a condimentum vitae sapien pellentesque habitant morbi tristique senectus.

      Faucibus scelerisque eleifend donec pretium vulputate sapien nec sagittis
      aliquam. Nulla facilisi nullam vehicula ipsum a. Donec enim diam vulputate
      ut. Ornare arcu dui vivamus arcu felis bibendum ut tristique et. Malesuada
      fames ac turpis egestas maecenas pharetra convallis posuere morbi.
    )
    links [
      {
        label: 'Open Source',
        url: 'https://github.com/inferno-framework/inferno-core'
      },
      {
        label: 'Issues',
        url: 'https://github.com/inferno-framework/inferno-core/issues'
      }
    ]

    fhir_resource_validator required_suite_options: { ig_version: '1' } do
      url 'https://example.com/v1_validator'
    end

    fhir_resource_validator required_suite_options: { ig_version: '2' } do
      url 'https://example.com/v2_validator'
    end

    suite_option :ig_version,
                 title: 'IG Version',
                 description: 'Which IG Version should be used',
                 default: '2',
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

    suite_option :other_option,
                 title: 'Another option',
                 description: 'Another potential thing that could be used',
                 list_options: [
                   {
                     label: 'option 1',
                     value: '1'
                   },
                   {
                     label: 'option 2',
                     value: '2'
                   },
                   {
                     label: 'option 3',
                     value: '3'
                   }
                 ]

    group from: :all_versions_group

    group from: :v1_group,
          required_suite_options: { ig_version: '1' }

    group from: :v2_group,
          required_suite_options: { ig_version: '2' }
  end
end
