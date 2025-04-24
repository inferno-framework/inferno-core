require_relative 'empty_group'
require_relative 'external_outer_group'
require_relative 'failing_optional_group'
require_relative 'json_test_endpoint'
require_relative 'mixed_optional_group'
require_relative 'passing_optional_group'

module DevelopmentTestKit
  class InfrastructureSuite < Inferno::TestSuite
    id 'infra_test'
    title 'Infrastructure Test Suite'
    short_title 'Infrastructure'
    description 'An internal test suite to verify that inferno infrastructure works'
    short_description 'Internal test suite'
    input_instructions %(
      Instructions for inputs
      * Bulletted List
      * Here
      `code here`
    )
    version '42.0'
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

    suite_endpoint :post, '/json_test', JSONTestEndpoint

    input :suite_input
    output :suite_output

    check_configuration do
      [
        {
          type: 'error',
          message: 'This suite has a configuration error message'
        }
      ]
    end

    def suite_helper
      'SUITE_HELPER'
    end

    fhir_client :suite do
      url 'SUITE'
    end

    group 'Outer inline group title', id: 'outer_inline_group' do
      input :outer_group_input
      output :outer_group_output
      short_title 'Outer inline group short title'
      description 'Outer inline group for testing description'
      short_description 'Outer inline group short description'

      def outer_inline_group_helper
        'OUTER_INLINE_GROUP_HELPER'
      end

      fhir_client :outer_inline_group do
        url 'OUTER_INLINE_GROUP'
      end

      group 'Inner inline group', id: 'inner_inline_group' do
        input :inner_group_input
        output :inner_group_output
        short_title 'Inner inline group short title'

        def inner_inline_group_helper
          'INNER_INLINE_GROUP_HELPER'
        end

        fhir_client :inner_inline_group do
          url 'INNER_INLINE_GROUP'
        end

        test 'Inline test 1', id: 'inline_test_1' do
          input :test_input
          output :test_output
          short_title 'Inline test 1'
          description 'Inline test 1 full description'
          short_description 'Inline test 1 short description'

          def inline_test1_helper
            'INLINE_TEST1_HELPER'
          end

          fhir_client :inline_test1 do
            url 'INLINE_TEST1'
          end

          run { assert inline_test1_helper == 'INLINE_TEST1_HELPER' }
        end

        test 'Inline test 2', id: 'inline_test_2' do
          run { assert inner_inline_group_helper == 'INNER_INLINE_GROUP_HELPER' }
        end

        test 'Inline test 3', id: 'inline_test_3' do
          run { assert outer_inline_group_helper == 'OUTER_INLINE_GROUP_HELPER' }
        end

        test 'Inline test 4', id: 'inline_test_4' do
          run { assert suite_helper == 'SUITE_HELPER' }
        end
      end
    end

    group from: 'passing_optional_group'
    group from: 'failing_optional_group'
    group from: 'mixed_optional_group', exclude_optional: true
    group from: 'empty_group'
    group from: 'external_outer_group'
  end
end
