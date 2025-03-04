RSpec.describe Inferno::DSL::FHIRResourceValidation do
  let(:validation_url) { 'http://example.com' }
  let(:profile_url) { 'PROFILE' }
  let(:validator) do
    Inferno::DSL::FHIRResourceValidation::Validator.new('test_validator', 'test_suite') do
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
              fileName: 'Patient/id.json',
              fileContent: resource.source_contents,
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
          doNative: false,
          extensions: ['any'],
          disableDefaultResourceFetcher: true,
          profiles: [profile_url]
        },
        filesToValidate: [
          {
            fileName: 'Patient/0000.json',
            fileContent: resource2.source_contents,
            fileType: 'json'
          }
        ],
        sessionId: nil
      }.to_json
    end

    context 'with invalid resource' do
      let(:invalid_outcome) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Patient/0000.json',
                fileContent: resource_string.to_json,
                fileType: 'json'
              },
              issues: [
                {
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
                },
                {
                  source: 'InstanceValidator',
                  line: 5,
                  col: 5,
                  location: 'Patient',
                  message: "URL value 'http://example.com/fhir/StructureDefinition/patient' does not resolve",
                  messageId: 'Patient_Profile',
                  type: 'CODEINVALID',
                  level: 'ERROR',
                  html: "URL value 'http://example.com/fhir/StructureDefinition/patient' does not resolve",
                  display: "URL value 'http://example.com/fhir/StructureDefinition/patient' does not resolve",
                  error: true
                }
              ]
            }
          ],
          sessionId: 'b8cf5547-1dc7-4714-a797-dc2347b93fe2'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .with(body: wrapped_resource_string)
          .to_return(status: 200, body: invalid_outcome)
      end

      context 'when add_messages_to_runnable is set to true' do
        it 'includes resourceType/id in error message' do
          result = validator.resource_is_valid?(resource2, profile_url, runnable)

          expect(result).to be(false)
          expect(runnable.messages.first[:message]).to start_with("#{resource2.resourceType}/#{resource2.id}:")
        end

        it 'excludes the unresolved url message' do
          result = validator.resource_is_valid?(resource2, profile_url, runnable)

          expect(result).to be(false)
          expect(runnable.messages)
            .to all(satisfy { |message| !message[:message].match?(/\A\S+: [^:]+: URL value '.*' does not resolve/) })
        end
      end

      context 'when add_messages_to_runnable is set to false' do
        it 'does not log messages' do
          result = validator.resource_is_valid?(resource2, profile_url, runnable, add_messages_to_runnable: false)

          expect(result).to be(false)
          expect(runnable.messages).to be_empty
        end
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

    it 'removes non-printable characters from the response' do
      stub_request(:post, "#{validation_url}/validate")
        .with(body: wrapped_resource_string)
        .to_return(
          status: 500,
          body: "<html><body>Internal Server Error: content#{0.chr} with non-printable#{1.chr} characters</body></html>"
        )

      expect do
        validator.resource_is_valid?(resource2, profile_url, runnable)
      end.to raise_error(Inferno::Exceptions::ErrorInValidatorException)

      msg = runnable.messages.first[:message]
      expect(msg).to_not include(0.chr)
      expect(msg).to_not include(1.chr)
      expect(msg).to match(/Internal Server Error: content with non-printable/)
    end
  end

  describe '.cli_context' do
    it 'applies the correct settings to cli_context' do
      v1 = Inferno::DSL::FHIRResourceValidation::Validator.new do
        url 'http://example.com'
        cli_context do
          txServer nil
        end
      end

      v2 = Inferno::DSL::FHIRResourceValidation::Validator.new do
        url 'http://example.com'
        cli_context({
                      displayWarnings: true
                    })
      end

      v3 = Inferno::DSL::FHIRResourceValidation::Validator.new do
        url 'http://example.com'
        cli_context({
                      'igs' => ['hl7.fhir.us.core#1.0.1'],
                      'extensions' => []
                    })
      end

      expect(v1.cli_context.definition.fetch(:txServer, :missing)).to be_nil
      expect(v1.cli_context.definition.fetch(:displayWarnings, :missing)).to eq(:missing)
      expect(v1.cli_context.txServer).to be_nil

      expect(v2.cli_context.definition.fetch(:txServer, :missing)).to eq(:missing)
      expect(v2.cli_context.definition[:displayWarnings]).to be(true)
      expect(v2.cli_context.displayWarnings).to be(true)

      expect(v3.cli_context.igs).to eq(['hl7.fhir.us.core#1.0.1'])
      expect(v3.cli_context.extensions).to eq([])
    end

    it 'uses the right cli_context when submitting the validation request' do
      v4 = Inferno::DSL::FHIRResourceValidation::Validator.new do
        url 'http://example.com'
        igs 'hl7.fhir.us.core#1.0.1'
        cli_context do
          txServer nil
          displayWarnings true
          doNative true
          igs ['hl7.fhir.us.core#3.1.1']
        end
      end

      expected_request_body = {
        cliContext: {
          sv: '4.0.1',
          doNative: true,
          extensions: ['any'],
          disableDefaultResourceFetcher: true,
          igs: ['hl7.fhir.us.core#3.1.1'],
          txServer: nil,
          displayWarnings: true,
          profiles: [profile_url]
        },
        filesToValidate: [
          {
            fileName: 'Patient/.json',
            fileContent: resource.source_contents,
            fileType: 'json'
          }
        ],
        sessionId: nil
      }.to_json

      stub_request(:post, 'http://example.com/validate')
        .with(body: expected_request_body)
        .to_return(status: 200, body: '{}')

      expect(v4.validate(resource, profile_url)).to eq('{}')
      # if the request body doesn't match the stub,
      # validate will throw an exception
    end
  end

  describe '.find_validator' do
    it 'finds the correct validator based on suite options' do
      suite = OptionsSuite::Suite

      v1_validator = suite.find_validator(:default, ig_version: '1')
      v2_validator = suite.find_validator(:default, ig_version: '2')

      expect(v1_validator.url).to eq('https://example.com/v1_validator')
      expect(v2_validator.url).to eq('https://example.com/v2_validator')
    end
  end

  describe '#find_validator' do
    it 'finds the correct validator based on suite options' do
      test_class = OptionsSuite::Suite.groups.first.tests.first
      v1_test = test_class.new(suite_options: { ig_version: '1' })
      v2_test = test_class.new(suite_options: { ig_version: '2' })

      v1_validator = v1_test.find_validator(:default)
      v2_validator = v2_test.find_validator(:default)

      expect(v1_validator.url).to eq('https://example.com/v1_validator')
      expect(v2_validator.url).to eq('https://example.com/v2_validator')
    end
  end
end
