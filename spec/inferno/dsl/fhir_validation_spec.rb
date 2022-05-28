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
    let(:resource_string) do
      {
        resourceType: 'Patient',
        id: '0000',
        _gender: {
          extension: [
            {
              url: 'http: //hl7.org/fhir/StructureDefinition/data-absent-reason',
              valueCode: 'unknown'
            }
          ]
        }
      }.to_json
    end
    let(:resource) { FHIR.from_contents(resource_string) }

    context 'with invalid resource' do
      let(:invalid_outcome) do
        {
          resourceType: 'OperationOutcome',
          issue: [
            {
              severity: 'error',
              code: 'processing',
              diagnostics: 'Identifier.system must be an absolute reference, not a local reference',
              location: [
                'Patient.identifier[0]',
                'Line 14, Col 10'
              ]
            }
          ]
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate?profile=#{profile_url}")
          .with(body: resource_string)
          .to_return(status: 200, body: invalid_outcome)
      end

      it 'includes resourceType/id in error message' do
        result = validator.resource_is_valid?(resource, profile_url, runnable)

        expect(result).to be(false)
        expect(runnable.messages.first[:message]).to include("#{resource.resourceType}/#{resource.id}/")
      end

      it 'includes resourceType/id in error message if resource.id is nil' do
        resource.id = nil
        result = validator.resource_is_valid?(resource, profile_url, runnable)

        expect(result).to be(false)
        expect(runnable.messages.first[:message]).to include("#{resource.resourceType}/")
      end
    end

    it 'posts the resource with primitive extensions intact' do
      stub_request(:post, "#{validation_url}/validate?profile=#{profile_url}")
        .with(body: resource_string)
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      expect(validator.resource_is_valid?(resource, profile_url, runnable)).to be(true)
    end
  end
end
