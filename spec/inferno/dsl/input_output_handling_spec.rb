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

    it 'walks each child subtree only once' do
      suite = Class.new(Inferno::Entities::TestSuite) do
        id SecureRandom.uuid
        input :a, :b, :c

        group do
          input :a, :b, :c
          test do
            input :a, :b, :c
            run { nil }
          end
        end
      end

      call_count = 0
      counter = Module.new do
        define_method(:children_available_inputs) do |*args|
          call_count += 1
          super(*args)
        end
      end
      suite.singleton_class.prepend(counter)

      suite.available_inputs

      expect(call_count).to eq(1)
    end
  end

  describe '.missing_inputs' do
    it 'requires a conditional input only when its condition matches' do
      example_test = Class.new(Inferno::Entities::Test)
      example_test.input :mode, optional: true
      example_test.input :details, enable_when: { input_name: 'mode', value: 'advanced' }

      expect(example_test.missing_inputs([], nil)).to eq([])
      expect(example_test.missing_inputs([{ name: 'mode', value: 'basic' }], nil)).to eq([])
      expect(example_test.missing_inputs([{ name: 'mode', value: 'advanced' }], nil)).to eq(['details'])
    end

    it 'normalizes array values when evaluating conditional inputs' do
      example_test = Class.new(Inferno::Entities::Test)
      example_test.input :selections, type: 'checkbox', optional: true,
                                      options: { list_options: [
                                        { label: 'A', value: 'a' }, { label: 'B', value: 'b' }
                                      ] }
      example_test.input :details, enable_when: { input_name: 'selections', value: '["a","b"]' }

      missing_inputs = example_test.missing_inputs([{ name: 'selections', value: %w[b a] }], nil)

      expect(missing_inputs).to eq(['details'])
    end

    it 'requires a checkbox-controlled input when serialized selections match in a different order' do
      example_test = Class.new(Inferno::Entities::Test)
      example_test.input :selections, type: 'checkbox', optional: true,
                                      options: { list_options: [
                                        { label: 'A', value: 'a' }, { label: 'B', value: 'b' }
                                      ] }
      example_test.input :details, enable_when: { input_name: 'selections', value: '["a","b"]' }

      expect(example_test.missing_inputs([{ name: 'selections', value: '["b","a"]' }], nil)).to eq(['details'])
      expect(example_test.missing_inputs([{ name: 'selections', value: '["b"]' }], nil)).to eq([])
    end

    it 'compares a text input containing JSON literally' do
      example_test = Class.new(Inferno::Entities::Test)
      example_test.input :selections, optional: true
      example_test.input :details, enable_when: { input_name: 'selections', value: '["a","b"]' }

      expect(example_test.missing_inputs([{ name: 'selections', value: '["b","a"]' }], nil)).to eq([])
    end

    it 'does not require an input whose controlling input is itself disabled' do
      example_test = Class.new(Inferno::Entities::Test)
      example_test.input :mode, optional: true
      example_test.input :sub_mode, optional: true, enable_when: { input_name: 'mode', value: 'advanced' }
      example_test.input :details, enable_when: { input_name: 'sub_mode', value: 'x' }

      submitted = [{ name: 'mode', value: 'basic' }, { name: 'sub_mode', value: 'x' }]
      # sub_mode has a matching value, but it is not itself enabled since mode != 'advanced'
      expect(example_test.missing_inputs(submitted, nil)).to eq([])

      submitted = [{ name: 'mode', value: 'advanced' }, { name: 'sub_mode', value: 'x' }]
      expect(example_test.missing_inputs(submitted, nil)).to eq(['details'])
    end

    it 'requires an input whose controlling input is merely hidden, not conditionally disabled' do
      example_test = Class.new(Inferno::Entities::Test)
      example_test.input :ctrl, optional: true, hidden: true
      example_test.input :details, enable_when: { input_name: 'ctrl', value: 'x' }

      # `hidden` alone is a static display flag, not a conditional disable, so it
      # should not block an enable_when chain
      expect(example_test.missing_inputs([{ name: 'ctrl', value: 'x' }], nil)).to eq(['details'])
    end

    it 'does not loop forever on a circular enable_when chain' do
      example_test = Class.new(Inferno::Entities::Test)
      example_test.input :a, optional: true, enable_when: { input_name: 'b', value: 'x' }
      example_test.input :b, optional: true, enable_when: { input_name: 'a', value: 'y' }

      submitted = [{ name: 'a', value: 'y' }, { name: 'b', value: 'x' }]
      expect(example_test.missing_inputs(submitted, nil)).to eq([])
    end

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

  describe '.enable_when_cycle_messages' do
    it 'is available on Test, TestGroup, and TestSuite' do
      test = Class.new(Inferno::Entities::Test)
      group = Class.new(Inferno::Entities::TestGroup)
      suite = Class.new(Inferno::Entities::TestSuite) { id SecureRandom.uuid }

      expect(test.enable_when_cycle_messages).to eq([])
      expect(group.enable_when_cycle_messages).to eq([])
      expect(suite.enable_when_cycle_messages).to eq([])
    end

    it 'detects a cycle local to a single test' do
      test = Class.new(Inferno::Entities::Test)
      test.input :a, optional: true, enable_when: { input_name: 'b', value: 'x' }
      test.input :b, optional: true, enable_when: { input_name: 'a', value: 'y' }

      expect(test.enable_when_cycle_messages.length).to eq(1)
    end

    it 'can be hidden from a suite-level check when a parent redeclares the input without enable_when' do
      suite = Class.new(Inferno::Entities::TestSuite) do
        id SecureRandom.uuid

        group do
          id 'g'
          # Redeclaring :a here with no enable_when is the normal pattern for
          # "pulling up"/reusing an input at a higher level; enable_when only
          # has meaning at the level it's declared, so this intentionally
          # does not propagate up.
          input :a

          test do
            id 't'
            input :a, enable_when: { input_name: 'b', value: 'x' }
            input :b, enable_when: { input_name: 'a', value: 'y' }
            run { pass }
          end
        end
      end

      # The suite's own merged view no longer sees :a's enable_when, so it
      # misses the cycle...
      expect(suite.enable_when_cycle_messages).to eq([])

      # ...but checking every runnable in the tree (not just the suite)
      # still catches it, at the level (the test) where it's actually
      # declared.
      all_messages = [suite, *suite.all_descendants].flat_map(&:enable_when_cycle_messages)
      expect(all_messages.length).to eq(1)
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
