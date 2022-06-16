RSpec.describe Inferno::DSL::FHIRValidation do
  let(:validation_url) { 'http://example.com' }
  let(:profile_url) { 'PROFILE' }
  let(:validator) do
    Inferno::DSL::FHIRValidation::Validator.new do
      url 'http://example.com'
    end
  end
  let(:runnable) do
    Inferno::Entities::Test.new
  end
  let(:resource) { FHIR::Patient.new }

  describe '#perform_additional_validation' do
    before do
      stub_request(:post, "#{validation_url}/validate?profile=#{profile_url}")
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)
    end

    context 'when the step does not return a hash' do
      it 'does not add any messages to the runnable' do
        validator.perform_additional_validation { 1 }
        validator.perform_additional_validation { nil }

        expect(validator.resource_is_valid?(resource, profile_url, runnable)).to be(true)
        expect(runnable.messages).to eq([])
      end
    end

    context 'when the step returns an hash' do
      let(:extra_message) do
        { type: 'info', message: 'INFO' }
      end

      it 'adds the messages to the runnable' do
        validator.perform_additional_validation { extra_message }

        expect(validator.resource_is_valid?(resource, profile_url, runnable)).to be(true)
        expect(runnable.messages).to eq([extra_message])
      end
    end

    context 'when the step returns an array of hashes' do
      let(:extra_messages) do
        [
          { type: 'info', message: 'INFO' },
          { type: 'warning', message: 'WARNING' }
        ]
      end

      it 'adds the messages to the runnable' do
        validator.perform_additional_validation { extra_messages }

        expect(validator.resource_is_valid?(resource, profile_url, runnable)).to be(true)
        expect(runnable.messages).to eq(extra_messages)
      end
    end

    context 'when the step returns an error message' do
      let(:extra_messages) do
        [
          { type: 'info', message: 'INFO' },
          { type: 'error', message: 'ERROR' }
        ]
      end

      it 'fails validation' do
        validator.perform_additional_validation { extra_messages }

        expect(validator.resource_is_valid?(resource, profile_url, runnable)).to be(false)
        expect(runnable.messages).to eq(extra_messages)
      end
    end
  end

  describe '#resource_is_valid?' do
    it 'posts the resource with primitive extensions intact' do
      resource_string = {
        resourceType: 'Patient',
        _gender: {
          extension: [
            {
              url: 'http: //hl7.org/fhir/StructureDefinition/data-absent-reason',
              valueCode: 'unknown'
            }
          ]
        }
      }.to_json
      resource = FHIR.from_contents(resource_string)

      stub_request(:post, "#{validation_url}/validate?profile=#{profile_url}")
        .with(body: resource_string)
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      expect(validator.resource_is_valid?(resource, profile_url, runnable)).to be(true)
    end
  end

  describe '.find_validator' do
    it 'finds the correct validator based on suite options' do
      suite = OptionsSuite::Suite

      v1_validator = suite.find_validator(:default, ig_version: '1')
      v2_validator = suite.find_validator(:default, ig_version: '2')

      expect(v1_validator.url).to eq('v1_validator')
      expect(v2_validator.url).to eq('v2_validator')
    end
  end

  describe '#find_validator' do
    it 'finds the correct validator based on suite options' do
      test_class = OptionsSuite::Suite.groups.first.tests.first
      v1_test = test_class.new(suite_options: { ig_version: '1' })
      v2_test = test_class.new(suite_options: { ig_version: '2' })

      v1_validator = v1_test.find_validator(:default)
      v2_validator = v2_test.find_validator(:default)

      expect(v1_validator.url).to eq('v1_validator')
      expect(v2_validator.url).to eq('v2_validator')
    end
  end
end
