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
            },
            {
              severity: 'error',
              code: 'processing',
              details: {
                text: 'The valueSet reference https://example.org could not be resolved'
              },
              location: [
                'Organization.type',
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

      context 'when add_messages_to_runnable is set to true' do
        it 'includes resourceType/id in error message' do
          result = validator.resource_is_valid?(resource, profile_url, runnable)

          expect(result).to be(false)
          expect(runnable.messages.first[:message]).to start_with("#{resource.resourceType}/#{resource.id}:")
        end

        it 'includes resourceType in error message if resource.id is nil' do
          resource.id = nil
          result = validator.resource_is_valid?(resource, profile_url, runnable)

          expect(result).to be(false)
          expect(runnable.messages.first[:message]).to start_with("#{resource.resourceType}:")
        end

        it 'excludes the unresolved url message' do
          result = validator.resource_is_valid?(resource, profile_url, runnable)

          expect(result).to be(false)
          expect(runnable.messages).to all(satisfy { |message| !message[:message].match?(/could not be resolved/i) })
        end
      end

      context 'when add_messages_to_runnable is set to false' do
        it 'does not log messages' do
          resource.id = nil
          result = validator.resource_is_valid?(resource, profile_url, runnable, add_messages_to_runnable: false)

          expect(result).to be(false)
          expect(runnable.messages).to be_empty
        end
      end
    end

    context 'with error from validator' do
      let(:error_outcome) do
        {
          resourceType: 'OperationOutcome',
          issue: [
            {
              severity: 'fatal',
              code: 'structure',
              diagnostics: 'Validator still warming up... Please wait',
              details: {
                text: 'Validator still warming up... Please wait'
              }
            }
          ]
        }.to_json
      end

      it 'throws ErrorInValidatorException when validator not ready yet' do
        stub_request(:post, "#{validation_url}/validate?profile=#{profile_url}")
          .with(body: resource_string)
          .to_return(status: 503, body: error_outcome)

        expect do
          validator.resource_is_valid?(resource, profile_url, runnable)
        end.to raise_error(Inferno::Exceptions::ErrorInValidatorException)
        expect(runnable.messages.first[:message]).to include('Validator still warming up... Please wait')
      end

      it 'throws ErrorInValidatorException for non-JSON response' do
        stub_request(:post, "#{validation_url}/validate?profile=#{profile_url}")
          .with(body: resource_string)
          .to_return(status: 500, body: '<html><body>Internal Server Error</body></html>')

        expect do
          validator.resource_is_valid?(resource, profile_url, runnable)
        end.to raise_error(Inferno::Exceptions::ErrorInValidatorException)
      end
    end

    it 'posts the resource with primitive extensions intact' do
      stub_request(:post, "#{validation_url}/validate?profile=#{profile_url}")
        .with(body: resource_string)
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      expect(validator.resource_is_valid?(resource, profile_url, runnable)).to be(true)
    end

    it 'removes non-printable characters from the response' do
      stub_request(:post, "#{validation_url}/validate?profile=#{profile_url}")
        .with(body: resource_string)
        .to_return(
          status: 500,
          body: "<html><body>Internal Server Error: content#{0.chr} with non-printable#{1.chr} characters</body></html>"
        )

      expect do
        validator.resource_is_valid?(resource, profile_url, runnable)
      end.to raise_error(Inferno::Exceptions::ErrorInValidatorException)

      msg = runnable.messages.first[:message]
      expect(msg).to_not include(0.chr)
      expect(msg).to_not include(1.chr)
      expect(msg).to match(/Internal Server Error: content with non-printable/)
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
