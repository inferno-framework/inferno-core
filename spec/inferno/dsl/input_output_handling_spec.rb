RSpec.describe Inferno::DSL::InputOutputHandling do
  describe '.available_inputs' do
    it 'does not combine differently named child inputs' do
      group = Class.new(Inferno::Entities::TestGroup) do
        id SecureRandom.uuid
        group do
          config(inputs: { a: { name: :b } })
          test do
            input :a
          end
        end

        group do
          config(inputs: { a: { name: :c } })
          test do
            input :a
          end
        end
      end

      expect(group.available_inputs.length).to eq(2)
      expect(group.available_inputs.values.map(&:name)).to eq(['b', 'c'])
    end

    it 'does not duplicate renamed inputs' do
      suite = Class.new(Inferno::Entities::TestSuite) do
        group do
          input :a, name: :b

          test do
            run { nil }
          end
        end
      end
      group = suite.groups.first
      test = group.tests.first

      expect(suite.available_inputs.keys).to eq([:b])
      expect(group.available_inputs.keys).to eq([:b])
      expect(test.available_inputs.keys).to eq([:b])
    end

    it 'filters inputs based on selected suite_options' do
      v1_option = Inferno::DSL::SuiteOption.new(id: :ig_version, value: '1')
      v2_option = Inferno::DSL::SuiteOption.new(id: :ig_version, value: '2')
      v1_inputs = OptionsSuite::Suite.available_inputs([v1_option])
      v2_inputs = OptionsSuite::Suite.available_inputs([v2_option])

      expect(v1_inputs.length).to eq(2)
      expect(v2_inputs.length).to eq(2)

      expect(v1_inputs).to include(:v1_input, :all_versions_input)
      expect(v2_inputs).to include(:v2_input, :all_versions_input)
    end
  end

  describe '.missing_inputs' do
    it 'returns missing inputs for a test' do
      example_test = Class.new(Inferno::Entities::Test)
      example_test.input :a, :b, :c
      example_test.input :d, optional: true
      missing_inputs = example_test.missing_inputs([{ name: 'a', value: 'a' }], nil)
      expect(missing_inputs).to eq(['b', 'c'])

      missing_inputs = example_test.missing_inputs([{ name: 'a', value: 'a' }, { name: 'b', value: 'b' },
                                                    { name: 'c', value: 'c' }], nil)
      expect(missing_inputs).to eq([])
    end

    it 'looks through children for required inputs' do
      example_test_group = Class.new(Inferno::Entities::TestGroup)
      example_test_group.input :e, :f
      example_test_group.test 'child test' do
        input :a, :b, :c
        input :d, optional: true
      end
      missing_inputs = example_test_group.missing_inputs([{ name: 'a', value: 'a' }, { name: 'e', value: 'e' }], nil)
      expect(missing_inputs).to eq(['f', 'b', 'c'])

      missing_inputs = example_test_group.missing_inputs([{ name: 'a', value: 'a' }, { name: 'b', value: 'b' },
                                                          { name: 'c', value: 'c' }, { name: 'e', value: 'e' },
                                                          { name: 'f', value: 'f' }], nil)
      expect(missing_inputs).to eq([])
    end

    it 'respects outputs of prior tests' do
      example_test_group = Class.new(Inferno::Entities::TestGroup)
      example_test_group.test 'child test with outputs' do
        input :a, :b
        output :c
      end
      example_test_group.test 'child test uses output' do
        input :c, :d
      end
      missing_inputs = example_test_group.missing_inputs([{ name: 'a', value: 'a' }, { name: 'd', value: 'd' }], nil)
      expect(missing_inputs).to eq(['b'])
    end

    it 'does not include output that in a later test' do
      example_test_group = Class.new(Inferno::Entities::TestGroup)
      example_test_group.test 'child test' do
        input :a, :b
      end
      example_test_group.test 'child test with output' do
        output :a
      end
      missing_inputs = example_test_group.missing_inputs([{ name: 'b', value: 'b' }], nil)
      expect(missing_inputs).to eq(['a'])
    end

    it 'handles renamed inputs' do
      example_test_group = Class.new(Inferno::Entities::TestGroup)
      example_test_group.input :url1
      example_test_group.test 'child test' do
        output :url2
      end
      example_test_group.test 'child test with output' do
        input :url1, name: :url2
      end

      missing_inputs = example_test_group.missing_inputs([{ name: 'url1', value: 'xyz' }], nil)

      expect(missing_inputs).to eq([])
    end

    it 'handles suite options' do
      suite = OptionsSuite::Suite
      v1_option = Inferno::DSL::SuiteOption.new(id: :ig_version, value: '1')
      v2_option = Inferno::DSL::SuiteOption.new(id: :ig_version, value: '2')

      missing_inputs = suite.missing_inputs([{ name: 'v1_input', value: 'abc' }], nil)
      expect(missing_inputs).to contain_exactly('v2_input', 'all_versions_input')

      missing_inputs = suite.missing_inputs([{ name: 'v1_input', value: 'abc' }], [v1_option])
      expect(missing_inputs).to contain_exactly('all_versions_input')

      missing_inputs = suite.missing_inputs([{ name: 'v1_input', value: 'abc' }], [v2_option])
      expect(missing_inputs).to contain_exactly('v2_input', 'all_versions_input')

      missing_inputs = suite.missing_inputs([{ name: 'v2_input', value: 'abc' }], [v1_option])
      expect(missing_inputs).to contain_exactly('v1_input', 'all_versions_input')
    end
  end

  describe '.input_order' do
    let(:group) do
      Class.new(Inferno::Entities::TestGroup) do
        input :a, name: :aa
        input :b, name: :bb
        input :c, name: :cc
      end
    end

    context 'when blank' do
      it 'does no ordering on the inputs' do
        group.input_order

        ordered_inputs = group.available_inputs.values.map(&:name)

        expect(ordered_inputs).to eq(['aa', 'bb', 'cc'])
      end
    end

    context 'when all inputs are present' do
      it 'orders the inputs' do
        group.input_order(:bb, :cc, :aa)

        ordered_inputs = group.available_inputs.values.map(&:name)

        expect(ordered_inputs).to eq(['bb', 'cc', 'aa'])
      end
    end

    context 'when some inputs are present' do
      it 'orders those inputs first' do
        group.input_order(:bb)

        ordered_inputs = group.available_inputs.values.map(&:name)

        expect(ordered_inputs).to eq(['bb', 'aa', 'cc'])
      end
    end
  end

  describe '.input' do
    it 'adds the input to all children' do
      group = Class.new(Inferno::TestGroup) do
        input :a

        test do
          title 'child test'
        end
      end

      group.children.each do |child|
        expect(child.inputs).to include(:a)
      end

      group.input(:b, description: 'abc')

      group.children.each do |child|
        expect(child.inputs).to include(:b)
        expect(child.config.input(:b).description).to eq('abc')
      end
    end
  end

  describe '.output' do
    it 'adds the output to all children' do
      group = Class.new(Inferno::TestGroup) do
        output :a

        test do
          title 'child test'
        end
      end

      group.children.each do |child|
        expect(child.outputs).to include(:a)
      end

      group.output(:b, type: :oauth_credentials)

      group.children.each do |child|
        expect(child.outputs).to include(:b)
        expect(child.config.outputs[:b][:type]).to eq(:oauth_credentials)
      end
    end
  end
end
