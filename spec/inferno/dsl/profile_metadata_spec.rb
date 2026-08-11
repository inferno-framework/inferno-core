require_relative '../../../lib/inferno/dsl/profile_metadata'

RSpec.describe Inferno::DSL::ProfileMetadata do
  describe '#initialize' do
    it 'accepts the built-in must_supports attribute' do
      metadata = described_class.new(must_supports: { elements: [{ path: 'status' }] })

      expect(metadata.must_supports).to eq(elements: [{ path: 'status' }])
    end

    it 'defaults must_supports to an empty hash when not provided' do
      metadata = described_class.new

      expect(metadata.must_supports).to eq({})
    end

    it 'raises when given a key that was not declared with .attribute' do
      expect { described_class.new(not_a_real_attribute: 'value') }
        .to raise_error(/Unknown Inferno::DSL::ProfileMetadata attribute: not_a_real_attribute/)
    end

    it 'accepts string keys the same as symbol keys' do
      metadata = described_class.new('must_supports' => { elements: [] })

      expect(metadata.must_supports).to eq(elements: [])
    end
  end

  describe '#to_hash' do
    it 'includes only attributes that were set' do
      metadata = described_class.new(must_supports: { elements: [] })

      expect(metadata.to_hash).to eq(must_supports: { elements: [] })
    end
  end

  describe '#must_support_strings' do
    it 'combines elements, slices, and extensions into a single sorted list' do
      metadata = described_class.new(
        must_supports: {
          elements: [{ path: 'status' }, { path: 'code.coding.code', fixed_value: '45473-6' }],
          slices: [{ path: 'category', slice_name: 'us-core' }],
          extensions: [{ path: 'extension', slice_name: 'us-core-race' }]
        }
      )

      expect(metadata.must_support_strings).to eq(
        [
          'category:us-core',
          'code.coding.code:45473-6',
          'extension:us-core-race',
          'status'
        ]
      )
    end

    it 'omits the colon suffix when there is no fixed_value or slice_name' do
      metadata = described_class.new(
        must_supports: {
          elements: [{ path: 'status' }],
          slices: [{ path: 'category' }],
          extensions: [{ path: 'extension' }]
        }
      )

      expect(metadata.must_support_strings).to eq(['category', 'extension', 'status'])
    end

    it 'returns an empty array when there are no must supports' do
      metadata = described_class.new

      expect(metadata.must_support_strings).to eq([])
    end
  end

  context 'with a subclass that declares additional attributes' do
    let(:subclass) do
      Class.new(described_class) do
        attribute :searches
      end
    end

    it 'accepts attributes declared on the subclass in addition to the base attributes' do
      metadata = subclass.new(must_supports: { elements: [] }, resource: 'Patient', searches: ['name'])

      expect(metadata.must_supports).to eq(elements: [])
      expect(metadata.resource).to eq('Patient')
      expect(metadata.searches).to eq(['name'])
    end

    it 'does not add subclass attributes to the base class' do
      subclass # force evaluation

      expect(described_class.attribute_names).to eq(
        %i[resource profile_url profile_name profile_version must_supports]
      )
    end

    it 'still raises for attributes not declared on the subclass' do
      expect { subclass.new(bindings: []) }
        .to raise_error(/Unknown .* attribute: bindings/)
    end

    describe '.from_file' do
      let(:full_subclass) do
        Class.new(described_class) do
          %i[
            name class_name version reformatted_version title short_description is_delayed interactions
            operations searches search_definitions include_params revincludes required_concepts
            mandatory_elements bindings references tests id file_name delayed_references
          ].each { |name| attribute name }
        end
      end

      it 'loads a generated metadata YAML file into a usable instance' do
        path = File.realpath(File.join(Dir.pwd, 'spec/fixtures/metadata/coverage_v610.yml'))

        metadata = full_subclass.from_file(path)

        expect(metadata.resource).to eq('Coverage')
        expect(metadata.must_supports[:elements]).to be_an(Array)
      end
    end
  end
end
