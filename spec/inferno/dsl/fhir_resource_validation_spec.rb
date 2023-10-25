RSpec.describe Inferno::DSL::FHIRResourceValidation do
  let(:validation_url) { 'http://example.com' }
  let(:profile_url) { 'PROFILE' }
  let(:validator) do
    Inferno::DSL::FHIRResourceValidation::Validator.new do
      url 'http://example.com'
    end
  end
  let(:runnable) do
    Inferno::Entities::Test.new
  end
  let(:resource) { FHIR::Patient.new }

  describe '#perform_additional_validation' do
    before do
      stub_request(:post, "#{validation_url}/validate")
        .to_return(status: 200, body: {
          outcomes: [{
            fileInfo: {
              fileName: 'manually_entered_file.json',
              fileContent: resource.to_json,
              fileType: 'json'
            },
            issues: []
          }],
          sessionId: '5c7f903b-7e46-4e83-bdc9-0248ad2ba5f5'
        }.to_json)
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
    let(:resource2) { FHIR.from_contents(resource_string) }

    let(:wrapped_resource_string) do
      {
        cliContext: {
          sv: '4.0.1',
          igs: [],
          profiles: [profile_url]
        },
        filesToValidate: [
          {
            fileName: 'manually_entered_file.json',
            fileContent: resource2.to_json,
            fileType: 'json'
          }
        ],
        sessionId: nil
      }.to_json
    end

    context 'with invalid resource' do
      let(:invalid_outcome) do
        {
          outcomes: [{
            fileInfo: {
              fileName: 'manually_entered_file.json',
              fileContent: resource_string.to_json,
              fileType: 'json'
            },
            issues: [{
              source: 'InstanceValidator',
              line: 4,
              col: 4,
              location: 'Patient.identifier[0]',
              message: 'Identifier.system must be an absolute reference, not a local reference',
              messageId: 'Type_Specific_Checks_DT_Identifier_System',
              type: 'CODEINVALID',
              level: 'ERROR',
              html: 'Identifier.system must be an absolute reference, not a local reference',
              display: 'ERROR: Patient.identifier[0]: Identifier.system must be an absolute reference, ',
              error: true
            }]
          }],
          sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .with(body: wrapped_resource_string)
          .to_return(status: 200, body: invalid_outcome)
      end

      it 'includes resourceType/id in error message' do
        result = validator.resource_is_valid?(resource2, profile_url, runnable)

        expect(result).to be(false)
        expect(runnable.messages.first[:message]).to start_with("#{resource2.resourceType}/#{resource2.id}:")
      end
    end

    it 'throws ErrorInValidatorException for non-JSON response' do
      stub_request(:post, "#{validation_url}/validate")
        .with(body: wrapped_resource_string)
        .to_return(status: 500, body: '<html><body>Internal Server Error</body></html>')

      expect do
        validator.resource_is_valid?(resource2, profile_url, runnable)
      end.to raise_error(Inferno::Exceptions::ErrorInValidatorException)
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
