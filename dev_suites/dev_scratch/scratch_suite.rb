# frozen_string_literal: true

module DevScratchSuite
  class ScratchSuite < Inferno::TestSuite
    title 'Scratch Suite'
    id :dev_scratch
    description 'Inferno Core Developer Suite that utilizes [scratch](https://inferno-framework.github.io/docs/advanced-test-features/scratch.html).'

    group do
      title 'Scratch Group'
      id :scratch_group

      test do
        title 'Store value in Scratch'
        id :scratch_store_test

        run do
          scratch[:dummy] = 'value'
          pass
        end
      end

      test do
        title 'Retrieve value in Scratch'
        id :scratch_retrieve_test

        run do
          info "Scratch: #{scratch}"
          assert scratch[:dummy] == 'value'
        end
      end

      test do
        title 'Store nested value'
        id :scratch_nested_store_test

        run do
          scratch[:nested] = { inner_key: 'inner_value' }
        end
      end

      test do
        title 'Retrieve nested value'
        id :retrieve_nested_store_test

        run do
          info "Scratch: #{scratch}"
          assert scratch.dig(:nested, :inner_key) == 'inner_value'
        end
      end
    end
  end
end
