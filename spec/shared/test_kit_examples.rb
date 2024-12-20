Rspec.shared_examples 'deployable_test_kit' do
  describe 'TestKit' do
    let(:test_kit_location) do
      Object.const_source_location(described_class.name)
    end
    let(:test_kit_gem) do
      Bundler.definition.specs.find { |gem| test_kit_location.start_with? gem.full_gem_path }
    end
    let(:base_path) { test_git_gem.full_gem_path }
    let(:test_kit) { described_class.const_get('Metadata') }

    it 'defines test kit in the Metadata class' do
      expect(test_kit).to be_a(Inferno::Entities::TestKit)
    end

    it 'relies on the test kit version rather than defining the version in the suites' do
      # TODO
    end

    it 'defines all required fields' do
      required_fields = [
        :id,
        :title,
        :description,
        :suite_ids,
        :version,
        :maturity
      ]

      required_fields.each do |field_name|
        expect(test_kit).send(field_name).to be_present
      end
    end

    it 'has a description with a <!-- break -->' do
      expect(test_kit.description).to include('<!-- break -->')
    end

    it 'has a maturity of "Low", "Medium", or "High"' do
      expect(['Low', 'Medium', 'High']).to include(test_kit.maturity)
    end
  end
end
