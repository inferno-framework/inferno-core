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

    [true, false].each do |feature_flag|
      context "when use_validation_context_key? feature flag is #{feature_flag}" do
        let(:context_key) { feature_flag ? :validationContext : :cliContext }

        let(:wrapped_resource_string) do
          {
            context_key => {
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

        before do
          allow(Inferno::Feature).to receive(:use_validation_context_key?).and_return(feature_flag)
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
                    },
                    {
                      source: 'InstanceValidator',
                      line: 6,
                      col: 6,
                      location: 'Patient.meta.profile[0]',
                      message: "No definition could be found for URL value 'http://example.com/fhir/StructureDefinition/another-profile'",
                      messageId: 'Profile_Not_Found',
                      type: 'CODEINVALID',
                      level: 'ERROR',
                      html: "No definition could be found for URL value 'http://example.com/fhir/StructureDefinition/another-profile'",
                      display: "No definition could be found for URL value 'http://example.com/fhir/StructureDefinition/another-profile'",
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

            it 'excludes both types of unresolved url messages' do
              result = validator.resource_is_valid?(resource2, profile_url, runnable)

              expect(result).to be(false)
              # Verify both types of unresolved URL messages are filtered out
              expect(runnable.messages)
                .to all(
                  satisfy do |message|
                    !message[:message].match?(/\A\S+: [^:]+: URL value '.*' does not resolve/) &&
                      !message[:message].match?(/\A\S+: [^:]+: No definition could be found for URL value '.*'/)
                  end
                )
              # Verify only the non-URL-related error message remains
              expect(runnable.messages.length).to eq(1)
              expect(runnable.messages.first[:message]).to include('Identifier.system must be an absolute reference')
            end
          end

          context 'when add_messages_to_runnable is set to false' do
            it 'does not log messages' do
              result = validator.resource_is_valid?(resource2, profile_url, runnable, add_messages_to_runnable: false)

              expect(result).to be(false)
              expect(runnable.messages).to be_empty
            end
          end

          context 'when network errors happen' do
            it 'handles connection failed or refused errors' do
              allow(validator).to receive(:call_validator).and_raise(
                Faraday::ConnectionFailed.new('Connection failed: example.com:443')
              )

              expect do
                validator.resource_is_valid?(resource, profile_url, runnable)
              end.to raise_error(Inferno::Exceptions::ErrorInValidatorException, /Connection failed to validator/)

              expect(runnable.messages.last[:message]).to include('Connection failed')
            end

            it 'handles timeout errors' do
              allow(validator).to receive(:call_validator).and_raise(
                Faraday::TimeoutError.new('Timeout error message')
              )

              expect do
                validator.resource_is_valid?(resource, profile_url, runnable)
              end.to raise_error(Inferno::Exceptions::ErrorInValidatorException, /Timeout while connecting to validator/)

              expect(runnable.messages.last[:message]).to include('Timeout')
            end

            it 'handles SSL errors' do
              allow(validator).to receive(:call_validator).and_raise(
                Faraday::SSLError.new('Self-signed certificate in certificate chain')
              )

              expect do
                validator.resource_is_valid?(resource, profile_url, runnable)
              end.to raise_error(Inferno::Exceptions::ErrorInValidatorException, /SSL error connecting to validator/)

              expect(runnable.messages.last[:message]).to include('Self-signed')
            end

            it 'handles server 400s' do
              allow(validator).to receive(:call_validator).and_raise(
                Faraday::ClientError.new('404 Not Found')
              )

              expect do
                validator.resource_is_valid?(resource, profile_url, runnable)
              end.to raise_error(Inferno::Exceptions::ErrorInValidatorException, /Client error \(4xx\) connecting to validator/)

              expect(runnable.messages.last[:message]).to include('404')
            end

            it 'handles server 500s' do
              allow(validator).to receive(:call_validator).and_raise(
                Faraday::ServerError.new('500 Server Error')
              )

              expect do
                validator.resource_is_valid?(resource, profile_url, runnable)
              end.to raise_error(Inferno::Exceptions::ErrorInValidatorException, /Server error \(5xx\) from validator/)

              expect(runnable.messages.last[:message]).to include('500')
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
          # Create JSON string with actual non-printable characters (not escaped)
          response_json = <<~JSON
            {
              "outcomes": [{
                "fileInfo": {
                  "fileName": "Patient/0000.json",
                  "fileContent": #{resource_string.to_json},
                  "fileType": "json"
                },
                "issues": [{
                  "location": "Patient.name",
                  "message": "Error with non-printable#{0.chr} characters#{1.chr}",
                  "level": "ERROR"
                }]
              }],
              "sessionId": "5c7f903b-7e46-4e83-bdc9-0248ad2ba5f5"
            }
          JSON

          stub_request(:post, "#{validation_url}/validate")
            .with(body: wrapped_resource_string)
            .to_return(status: 200, body: response_json)

          validator.resource_is_valid?(resource2, profile_url, runnable)

          msg = runnable.messages.first[:message]
          expect(msg).to_not include(0.chr)
          expect(msg).to_not include(1.chr)
          expect(msg).to match(/Error with non-printable characters/)
        end
      end
    end
  end

  describe '.validation_context' do
    it 'applies the correct settings to validation_context' do
      v1 = Inferno::DSL::FHIRResourceValidation::Validator.new do
        url 'http://example.com'
        validation_context do
          txServer nil
        end
      end

      v2 = Inferno::DSL::FHIRResourceValidation::Validator.new do
        url 'http://example.com'
        validation_context({
                             displayWarnings: true
                           })
      end

      v3 = Inferno::DSL::FHIRResourceValidation::Validator.new do
        url 'http://example.com'
        validation_context({
                             'igs' => ['hl7.fhir.us.core#1.0.1'],
                             'extensions' => []
                           })
      end

      expect(v1.validation_context.definition.fetch(:txServer, :missing)).to be_nil
      expect(v1.validation_context.definition.fetch(:displayWarnings, :missing)).to eq(:missing)
      expect(v1.validation_context.txServer).to be_nil

      expect(v2.validation_context.definition.fetch(:txServer, :missing)).to eq(:missing)
      expect(v2.validation_context.definition[:displayWarnings]).to be(true)
      expect(v2.validation_context.displayWarnings).to be(true)

      expect(v3.validation_context.igs).to eq(['hl7.fhir.us.core#1.0.1'])
      expect(v3.validation_context.extensions).to eq([])
    end

    it 'uses the right validation_context when submitting the validation request' do
      v4 = Inferno::DSL::FHIRResourceValidation::Validator.new do
        url 'http://example.com'
        igs 'hl7.fhir.us.core#1.0.1'
        validation_context do
          txServer nil
          displayWarnings true
          doNative true
          igs ['hl7.fhir.us.core#3.1.1']
        end
      end

      [true, false].each do |feature_flag|
        allow(Inferno::Feature).to receive(:use_validation_context_key?).and_return(feature_flag)

        context_key = feature_flag ? :validationContext : :cliContext

        expected_request_body = {
          context_key => {
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

    it 'maintains backward compatibility with cli_context' do
      v5 = Inferno::DSL::FHIRResourceValidation::Validator.new do
        url 'http://example.com'
        igs 'hl7.fhir.us.core#1.0.1'
        cli_context do
          txServer nil
          displayWarnings true
          doNative true
          igs ['hl7.fhir.us.core#3.1.1']
        end
      end

      expect(v5.validation_context.txServer).to be_nil
      expect(v5.validation_context.displayWarnings).to be(true)
      expect(v5.validation_context.doNative).to be(true)
      expect(v5.validation_context.igs).to eq(['hl7.fhir.us.core#3.1.1'])

      [true, false].each do |feature_flag|
        allow(Inferno::Feature).to receive(:use_validation_context_key?).and_return(feature_flag)

        context_key = feature_flag ? :validationContext : :cliContext

        expected_request_body = {
          context_key => {
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

        expect(v5.validate(resource, profile_url)).to eq('{}')
      end
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

  describe 'slice info processing' do
    let(:resource_string) do
      {
        resourceType: 'Coverage',
        id: '6b28604e-5574-46d9-8f7a-68055baa55ab'
      }.to_json
    end

    let(:coverage_resource) { FHIR.from_contents(resource_string) }

    context 'when Reference_REF_CantMatchChoice error has sliceInfo with only suppressible errors' do
      let(:outcome_with_suppressible_slice_errors) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Unable to find a profile match for #2 among choices: http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization',
                  messageId: 'Reference_REF_CantMatchChoice',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Unable to find a profile match for #2'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching against profile http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization|6.1.0',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details for #2 matching',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 773,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type.coding[0].system',
                      message: "No definition could be found for URL value 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType'",
                      messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                      type: 'INVALID',
                      level: 'ERROR',
                      html: 'No definition could be found'
                    }
                  ]
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_suppressible_slice_errors)
      end

      it 'suppresses both the main Reference error and detail issue when all slice errors are suppressible' do
        result = validator.resource_is_valid?(coverage_resource, profile_url, runnable)

        expect(result).to be(true)
        expect(runnable.messages).to be_empty
      end
    end

    context 'when Reference_REF_CantMatchChoice error has sliceInfo with mixed suppressible and real errors' do
      let(:outcome_with_mixed_slice_errors) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Unable to find a profile match for #2 among choices',
                  messageId: 'Reference_REF_CantMatchChoice',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Unable to find a profile match'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching against profile',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details for #2',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 773,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type.coding[0].system',
                      message: "No definition could be found for URL value 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType'",
                      messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                      type: 'INVALID',
                      level: 'ERROR',
                      html: 'No definition could be found'
                    },
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 663,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[0]',
                      message: 'Identifier.system must be an absolute reference',
                      messageId: 'Real_Validation_Error',
                      type: 'STRUCTURE',
                      level: 'ERROR',
                      html: 'Real validation error'
                    }
                  ]
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_mixed_slice_errors)
      end

      it 'keeps the Reference error as ERROR when real errors remain in sliceInfo' do
        result = validator.resource_is_valid?(coverage_resource, profile_url, runnable)

        expect(result).to be(false)
        expect(runnable.messages.length).to eq(2)
        expect(runnable.messages[0][:type]).to eq('error')
        expect(runnable.messages[0][:message]).to include('Unable to find a profile match')
        expect(runnable.messages[1][:type]).to eq('info')
        expect(runnable.messages[1][:message]).to include('Details for #2')
      end
    end

    context 'when Reference_REF_CantMatchChoice error has sliceInfo with only warnings' do
      let(:outcome_with_warning_slice_errors) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Unable to find a profile match for #2',
                  messageId: 'Reference_REF_CantMatchChoice',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Unable to find a profile match'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details for #2',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'TerminologyEngine',
                      line: 1,
                      col: 793,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type',
                      message: 'None of the codings provided are in the value set',
                      messageId: 'Terminology_TX_NoValid_2_CC',
                      type: 'CODEINVALID',
                      level: 'WARNING',
                      html: 'None of the codings provided'
                    }
                  ]
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_warning_slice_errors)
      end

      it 'suppresses the Reference error when only warnings remain in sliceInfo' do
        result = validator.resource_is_valid?(coverage_resource, profile_url, runnable)

        expect(result).to be(true)
        expect(runnable.messages).to be_empty
      end
    end

    context 'when Reference_REF_CantMatchChoice error has nested sliceInfo' do
      let(:outcome_with_nested_slice_info) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Unable to find a profile match',
                  messageId: 'Reference_REF_CantMatchChoice',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Unable to find a profile match'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 810,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1]',
                      message: 'This element does not match any known slice',
                      messageId: 'Details_for__matching_against_Profile_',
                      type: 'INFORMATIONAL',
                      level: 'INFORMATION',
                      html: 'Does not match slice',
                      slicingHint: true,
                      sliceInfo: [
                        {
                          source: 'InstanceValidator',
                          line: 1,
                          col: 773,
                          location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type.coding[0].system',
                          message: "No definition could be found for URL value 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType'",
                          messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                          type: 'INVALID',
                          level: 'ERROR',
                          html: 'No definition found'
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_nested_slice_info)
      end

      it 'recursively processes nested sliceInfo and suppresses when all nested errors are suppressible' do
        result = validator.resource_is_valid?(coverage_resource, profile_url, runnable)

        expect(result).to be(true)
        expect(runnable.messages).to be_empty
      end
    end

    context 'when Reference_REF_CantMatchChoice and Details have mismatched locations' do
      let(:outcome_with_mismatched_locations) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Unable to find a profile match',
                  messageId: 'Reference_REF_CantMatchChoice',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Unable to find a profile match'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 3000,
                  location: 'Coverage.payor[1]',
                  message: 'Details for #3 matching',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 773,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type.coding[0].system',
                      message: "No definition could be found for URL value 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType'",
                      messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                      type: 'INVALID',
                      level: 'ERROR',
                      html: 'No definition found'
                    }
                  ]
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_mismatched_locations)
      end

      it 'does not apply special processing when locations do not match' do
        result = validator.resource_is_valid?(coverage_resource, profile_url, runnable)

        expect(result).to be(false)
        # The reference error should remain as ERROR since the Details issue location doesn't match
        expect(runnable.messages.length).to eq(2)
        expect(runnable.messages[0][:type]).to eq('error')
        expect(runnable.messages[0][:message]).to include('Coverage.payor[0]')
      end
    end

    context 'when regular issues with sliceInfo are present' do
      let(:outcome_with_regular_slice_info) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 773,
                  location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type.coding[0].system',
                  message: "No definition could be found for URL value 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType'",
                  messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                  type: 'INVALID',
                  level: 'ERROR',
                  html: 'No definition found',
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 800,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1]',
                      message: 'Additional slice info',
                      messageId: 'Some_Other_Message',
                      type: 'INFORMATIONAL',
                      level: 'INFORMATION',
                      html: 'Slice info'
                    }
                  ]
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_regular_slice_info)
      end

      it 'does not expose sliceInfo details to the user' do
        result = validator.resource_is_valid?(coverage_resource, profile_url, runnable)

        expect(result).to be(true)
        # The URL resolution error should be suppressed
        expect(runnable.messages).to be_empty
      end
    end

    context 'when suppressible Reference error is present alongside other base-level errors' do
      let(:outcome_with_suppressed_reference_and_other_errors) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 1500,
                  location: 'Coverage.status',
                  message: 'The value provided is not in the value set',
                  messageId: 'Terminology_PassThrough_TX_Message',
                  type: 'CODEINVALID',
                  level: 'ERROR',
                  html: 'Invalid status value'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Unable to find a profile match for #2',
                  messageId: 'Reference_REF_CantMatchChoice',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Unable to find a profile match'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 773,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type.coding[0].system',
                      message: "No definition could be found for URL value 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType'",
                      messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                      type: 'INVALID',
                      level: 'ERROR',
                      html: 'No definition found'
                    }
                  ]
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2200,
                  location: 'Coverage.beneficiary',
                  message: 'Referenced resource does not exist',
                  messageId: 'REF_CANT_RESOLVE',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Cannot resolve reference'
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_suppressed_reference_and_other_errors)
      end

      it 'fails validation due to other base-level errors even when Reference error is suppressed' do
        result = validator.resource_is_valid?(coverage_resource, profile_url, runnable)

        expect(result).to be(false)
        # Should have 2 errors: the status error and the beneficiary reference error
        # The Reference_REF_CantMatchChoice and its Details should be suppressed
        expect(runnable.messages.length).to eq(2)
        expect(runnable.messages[0][:type]).to eq('error')
        expect(runnable.messages[0][:message]).to include('Coverage.status')
        expect(runnable.messages[1][:type]).to eq('error')
        expect(runnable.messages[1][:message]).to include('Coverage.beneficiary')
      end
    end

    context 'when Reference_REF_CantMatchChoice error has multiple Details messages with all suppressible errors' do
      let(:outcome_with_multiple_suppressible_details) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Unable to find a profile match for #2',
                  messageId: 'Reference_REF_CantMatchChoice',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Unable to find a profile match'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching against profile http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization|6.1.0',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details for #2 matching profile 1',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 773,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type.coding[0].system',
                      message: "No definition could be found for URL value 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType'",
                      messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                      type: 'INVALID',
                      level: 'ERROR',
                      html: 'No definition could be found for URL 1'
                    }
                  ]
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching against profile http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner|6.1.0',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details for #2 matching profile 2',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 850,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[2].system',
                      message: "No definition could be found for URL value 'http://terminology.hl7.org/CodeSystem/v2-0203'",
                      messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                      type: 'INVALID',
                      level: 'ERROR',
                      html: 'No definition could be found for URL 2'
                    }
                  ]
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching against profile http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient|6.1.0',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details for #2 matching profile 3',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 920,
                      location: 'Coverage.contained[1]/*Organization/2*/.type.coding[0].system',
                      message: "URL value 'http://example.org/unknown-codesystem' does not resolve",
                      messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                      type: 'INVALID',
                      level: 'ERROR',
                      html: 'URL does not resolve'
                    }
                  ]
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_multiple_suppressible_details)
      end

      it 'suppresses the Reference error and all Details when all errors across all Details are suppressible' do
        result = validator.resource_is_valid?(coverage_resource, profile_url, runnable)

        expect(result).to be(true)
        expect(runnable.messages).to be_empty
      end
    end

    context 'when Reference_REF_CantMatchChoice error has multiple Details with one containing real errors' do
      let(:outcome_with_multiple_details_with_real_error) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Unable to find a profile match for #2',
                  messageId: 'Reference_REF_CantMatchChoice',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Unable to find a profile match'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching against profile http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization|6.1.0',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details for #2 matching profile 1',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 773,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type.coding[0].system',
                      message: "No definition could be found for URL value 'http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType'",
                      messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                      type: 'INVALID',
                      level: 'ERROR',
                      html: 'No definition could be found for URL'
                    }
                  ]
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching against profile http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner|6.1.0',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details for #2 matching profile 2',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 850,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[0]',
                      message: 'Identifier.system must be an absolute reference, not a local reference',
                      messageId: 'Validation_VAL_Profile_Minimum',
                      type: 'STRUCTURE',
                      level: 'ERROR',
                      html: 'Real validation error in profile 2'
                    }
                  ]
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching against profile http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient|6.1.0',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details for #2 matching profile 3',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'InstanceValidator',
                      line: 1,
                      col: 920,
                      location: 'Coverage.contained[1]/*Organization/2*/.type.coding[0].system',
                      message: "URL value 'http://example.org/unknown-codesystem' does not resolve",
                      messageId: 'Type_Specific_Checks_DT_URL_Resolve',
                      type: 'INVALID',
                      level: 'ERROR',
                      html: 'URL does not resolve'
                    }
                  ]
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_multiple_details_with_real_error)
      end

      it 'suppresses the Reference error when at least one profile validates, even if others have real errors' do
        result = validator.resource_is_valid?(coverage_resource, profile_url, runnable)

        # With the new logic, since profile 1 (us-core-organization) and profile 3 (us-core-patient)
        # only have suppressible errors, they validate successfully. Since at least one profile validates,
        # the Reference error is suppressed even though profile 2 (us-core-practitioner) has real errors.
        expect(result).to be(true)
        expect(runnable.messages).to be_empty
      end
    end

    context 'when custom exclude_message filter is applied to slice issues' do
      let(:validator_with_custom_filter) do
        Inferno::DSL::FHIRResourceValidation::Validator.new('test_validator', 'test_suite') do
          url 'http://example.com'
          exclude_message do |message|
            # Filter that matches raw message patterns (without resource/location prefix)
            # This simulates filtering specific validation errors in slices
            message.message.match?(/could not be found, so the code cannot be validated/)
          end
        end
      end

      let(:outcome_with_custom_filterable_slice_errors) do
        {
          outcomes: [
            {
              fileInfo: {
                fileName: 'Coverage/6b28604e-5574-46d9-8f7a-68055baa55ab.json',
                fileContent: resource_string,
                fileType: 'json'
              },
              issues: [
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Unable to find a profile match for #2',
                  messageId: 'Reference_REF_CantMatchChoice',
                  type: 'STRUCTURE',
                  level: 'ERROR',
                  html: 'Unable to find a profile match'
                },
                {
                  source: 'InstanceValidator',
                  line: 1,
                  col: 2096,
                  location: 'Coverage.payor[0]',
                  message: 'Details for #2 matching',
                  messageId: 'Details_for__matching_against_Profile_',
                  type: 'STRUCTURE',
                  level: 'INFORMATION',
                  html: 'Details',
                  slicingHint: true,
                  sliceInfo: [
                    {
                      source: 'TerminologyEngine',
                      line: 1,
                      col: 793,
                      location: 'Coverage.contained[1]/*Organization/2*/.identifier[1].type.coding[0].system',
                      message: "A definition for CodeSystem 'http://example.com/custom' could not be found, " \
                               'so the code cannot be validated',
                      messageId: 'UNKNOWN_CODESYSTEM',
                      type: 'NOTFOUND',
                      level: 'ERROR',
                      html: 'Code system not found'
                    }
                  ]
                }
              ]
            }
          ],
          sessionId: '861f9cc3-688f-4fda-8cf8-4b8640432b5e'
        }.to_json
      end

      before do
        stub_request(:post, "#{validation_url}/validate")
          .to_return(status: 200, body: outcome_with_custom_filterable_slice_errors)
      end

      it 'applies custom exclude_message filter to slice issues' do
        result = validator_with_custom_filter.resource_is_valid?(coverage_resource, profile_url, runnable)

        expect(result).to be(true)
        # The custom filter should suppress the CodeSystem error in sliceInfo
        # which should cause both the Reference error and Details to be suppressed
        expect(runnable.messages).to be_empty
      end
    end
  end

  describe 'helper method unit tests' do
    describe '#convert_raw_issue_to_validator_issue' do
      it 'converts a basic raw issue to ValidatorIssue' do
        raw_issue = {
          'level' => 'ERROR',
          'location' => 'Patient.name',
          'message' => 'Name is required'
        }

        result = validator.convert_raw_issue_to_validator_issue(raw_issue, resource)

        expect(result).to be_a(Inferno::DSL::FHIRResourceValidation::ValidatorIssue)
        expect(result.severity).to eq('error')
        expect(result.location).to eq('Patient.name')
        expect(result.message).to include('Name is required')
        expect(result.slice_info).to be_empty
      end

      it 'recursively processes nested sliceInfo' do
        raw_issue = {
          'level' => 'ERROR',
          'location' => 'Coverage.payor[0]',
          'message' => 'Cannot match profile',
          'sliceInfo' => [
            {
              'level' => 'INFORMATION',
              'location' => 'Coverage.payor[0]',
              'message' => 'Details for matching',
              'sliceInfo' => [
                {
                  'level' => 'ERROR',
                  'location' => 'Coverage.contained[1].identifier',
                  'message' => 'Nested error'
                }
              ]
            }
          ]
        }

        result = validator.convert_raw_issue_to_validator_issue(raw_issue, resource)

        expect(result.slice_info.length).to eq(1)
        expect(result.slice_info[0].severity).to eq('info')
        expect(result.slice_info[0].slice_info.length).to eq(1)
        expect(result.slice_info[0].slice_info[0].severity).to eq('error')
        expect(result.slice_info[0].slice_info[0].message).to include('Nested error')
      end

      it 'handles raw issues without sliceInfo' do
        raw_issue = {
          'level' => 'WARNING',
          'location' => 'Patient.gender',
          'message' => 'Gender code not in value set'
        }

        result = validator.convert_raw_issue_to_validator_issue(raw_issue, resource)

        expect(result.slice_info).to be_empty
        expect(result.severity).to eq('warning')
      end
    end

    describe '#filter_individual_messages' do
      let(:unfiltered_issue) do
        Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'ERROR', 'location' => 'Patient.name', 'message' => 'Name required' },
          resource: resource,
          slice_info: [],
          filtered: false
        )
      end

      let(:url_resolve_issue) do
        Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'ERROR',
            'location' => 'Patient.extension',
            'message' => "URL value 'http://example.com/bad' does not resolve"
          },
          resource: resource,
          slice_info: [],
          filtered: false
        )
      end

      it 'marks unresolved URL messages as filtered' do
        issues = [url_resolve_issue]
        validator.filter_individual_messages(issues)

        expect(url_resolve_issue.filtered).to be(true)
      end

      it 'does not filter regular error messages' do
        issues = [unfiltered_issue]
        validator.filter_individual_messages(issues)

        expect(unfiltered_issue.filtered).to be(false)
      end

      it 'recursively filters nested slice_info' do
        nested_url_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'ERROR',
            'location' => 'Coverage.extension',
            'message' => "URL value 'http://bad.url' does not resolve"
          },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        parent_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'ERROR', 'location' => 'Coverage', 'message' => 'Parent error' },
          resource: resource,
          slice_info: [nested_url_issue],
          filtered: false
        )

        issues = [parent_issue]
        validator.filter_individual_messages(issues)

        expect(parent_issue.filtered).to be(false)
        expect(nested_url_issue.filtered).to be(true)
      end

      it 'applies custom exclude_message filter' do
        validator.exclude_message { |message| message.message.include?('custom filter') }

        custom_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'ERROR', 'location' => 'Patient', 'message' => 'custom filter applied' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        issues = [custom_issue]
        validator.filter_individual_messages(issues)

        expect(custom_issue.filtered).to be(true)
      end
    end

    describe '#apply_relationship_filters' do
      it 'processes Reference_REF_CantMatchChoice errors' do
        base_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'ERROR',
            'location' => 'Coverage.payor[0]',
            'message' => 'Unable to find profile match',
            'messageId' => 'Reference_REF_CantMatchChoice'
          },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        details_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'INFORMATION',
            'location' => 'Coverage.payor[0]',
            'message' => 'Details for # matching'
          },
          resource: resource,
          slice_info: [
            Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
              raw_issue: {
                'level' => 'ERROR',
                'location' => 'Coverage.contained',
                'message' => "URL value 'http://bad.url' does not resolve"
              },
              resource: resource,
              slice_info: [],
              filtered: true # Already filtered by filter_individual_messages
            )
          ],
          filtered: false
        )

        issues = [base_issue, details_issue]
        validator.apply_relationship_filters(issues)

        expect(base_issue.filtered).to be(true)
        expect(details_issue.filtered).to be(true)
      end

      it 'skips already filtered issues' do
        already_filtered = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'ERROR',
            'location' => 'Patient',
            'message' => 'Already filtered',
            'messageId' => 'Reference_REF_CantMatchChoice'
          },
          resource: resource,
          slice_info: [],
          filtered: true
        )

        issues = [already_filtered]
        # Should not raise error or change state
        expect { validator.apply_relationship_filters(issues) }.to_not raise_error
        expect(already_filtered.filtered).to be(true)
      end

      it 'recursively processes nested slice_info in depth-first order' do
        deeply_nested_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'ERROR',
            'location' => 'Coverage.contained[2]',
            'message' => 'Deep nested Reference error',
            'messageId' => 'Reference_REF_CantMatchChoice'
          },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        middle_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => 'Coverage.contained[1]', 'message' => 'Middle' },
          resource: resource,
          slice_info: [deeply_nested_issue],
          filtered: false
        )

        parent_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => 'Coverage', 'message' => 'Parent' },
          resource: resource,
          slice_info: [middle_issue],
          filtered: false
        )

        # Mock find_following_details_issues to return empty for nested call
        allow(validator).to receive(:find_following_details_issues).and_return([])

        issues = [parent_issue]
        validator.apply_relationship_filters(issues)

        # Verify recursion reached deeply nested issue
        expect(deeply_nested_issue.filtered).to be(false) # No details found, so not filtered
      end
    end

    describe '#should_filter_contained_resource?' do
      it 'returns false if issue is already filtered' do
        issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'ERROR',
            'location' => 'Coverage.payor[0]',
            'message' => 'Cannot match',
            'messageId' => 'Reference_REF_CantMatchChoice'
          },
          resource: resource,
          slice_info: [],
          filtered: true
        )

        expect(validator.should_filter_contained_resource?(issue)).to be(false)
      end

      it 'returns false if messageId is not Reference_REF_CantMatchChoice' do
        issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'ERROR',
            'location' => 'Patient.name',
            'message' => 'Name required',
            'messageId' => 'SomeOtherMessageId'
          },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        expect(validator.should_filter_contained_resource?(issue)).to be(false)
      end

      it 'returns false if severity is info' do
        issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'INFORMATION',
            'location' => 'Coverage.payor[0]',
            'message' => 'Cannot match',
            'messageId' => 'Reference_REF_CantMatchChoice'
          },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        expect(validator.should_filter_contained_resource?(issue)).to be(false)
      end

      it 'returns true for valid Reference_REF_CantMatchChoice error' do
        issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'ERROR',
            'location' => 'Coverage.payor[0]',
            'message' => 'Cannot match',
            'messageId' => 'Reference_REF_CantMatchChoice'
          },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        expect(validator.should_filter_contained_resource?(issue)).to be(true)
      end

      it 'returns true for valid Reference_REF_CantMatchChoice warning' do
        issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'WARNING',
            'location' => 'Coverage.payor[0]',
            'message' => 'Cannot match',
            'messageId' => 'Reference_REF_CantMatchChoice'
          },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        expect(validator.should_filter_contained_resource?(issue)).to be(true)
      end
    end

    describe '#at_least_one_valid_detail?' do
      it 'returns true when one detail has all error slices filtered' do
        valid_detail = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => 'Coverage', 'message' => 'Detail' },
          resource: resource,
          slice_info: [
            Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
              raw_issue: { 'level' => 'ERROR', 'location' => 'Coverage', 'message' => 'Error' },
              resource: resource,
              slice_info: [],
              filtered: true
            ),
            Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
              raw_issue: { 'level' => 'ERROR', 'location' => 'Coverage', 'message' => 'Error2' },
              resource: resource,
              slice_info: [],
              filtered: true
            )
          ],
          filtered: false
        )

        details_issues = [valid_detail]
        expect(validator.at_least_one_valid_detail?(details_issues)).to be(true)
      end

      it 'returns false when all details have unfiltered errors' do
        invalid_detail1 = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => 'Coverage', 'message' => 'Detail1' },
          resource: resource,
          slice_info: [
            Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
              raw_issue: { 'level' => 'ERROR', 'location' => 'Coverage', 'message' => 'Error' },
              resource: resource,
              slice_info: [],
              filtered: false
            )
          ],
          filtered: false
        )

        invalid_detail2 = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => 'Coverage', 'message' => 'Detail2' },
          resource: resource,
          slice_info: [
            Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
              raw_issue: { 'level' => 'ERROR', 'location' => 'Coverage', 'message' => 'Error2' },
              resource: resource,
              slice_info: [],
              filtered: false
            )
          ],
          filtered: false
        )

        details_issues = [invalid_detail1, invalid_detail2]
        expect(validator.at_least_one_valid_detail?(details_issues)).to be(false)
      end

      it 'returns true when detail has only warnings (no error slices)' do
        warning_detail = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => 'Coverage', 'message' => 'Detail' },
          resource: resource,
          slice_info: [
            Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
              raw_issue: { 'level' => 'WARNING', 'location' => 'Coverage', 'message' => 'Warning' },
              resource: resource,
              slice_info: [],
              filtered: false
            )
          ],
          filtered: false
        )

        details_issues = [warning_detail]
        expect(validator.at_least_one_valid_detail?(details_issues)).to be(true)
      end

      it 'returns true when at least one detail is valid among multiple' do
        valid_detail = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => 'Coverage', 'message' => 'Valid' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        invalid_detail = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => 'Coverage', 'message' => 'Invalid' },
          resource: resource,
          slice_info: [
            Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
              raw_issue: { 'level' => 'ERROR', 'location' => 'Coverage', 'message' => 'Error' },
              resource: resource,
              slice_info: [],
              filtered: false
            )
          ],
          filtered: false
        )

        details_issues = [invalid_detail, valid_detail]
        expect(validator.at_least_one_valid_detail?(details_issues)).to be(true)
      end
    end

    describe '#find_following_details_issues' do
      let(:base_location) { 'Coverage.payor[0]' }

      it 'finds consecutive Details messages at the same location' do
        base_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: {
            'level' => 'ERROR',
            'location' => base_location,
            'message' => 'Base error',
            'messageId' => 'Reference_REF_CantMatchChoice'
          },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        details1 = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => base_location, 'message' => 'Details for #1' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        details2 = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => base_location, 'message' => 'Details for #2' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        issues = [base_issue, details1, details2]
        result = validator.find_following_details_issues(issues, 0, base_location)

        expect(result.length).to eq(2)
        expect(result).to include(details1, details2)
      end

      it 'stops at first non-Details message' do
        base_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'ERROR', 'location' => base_location, 'message' => 'Base',
                       'messageId' => 'Reference_REF_CantMatchChoice' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        details1 = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => base_location, 'message' => 'Details for #1' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        other_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'ERROR', 'location' => base_location, 'message' => 'Other error' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        details2 = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => base_location, 'message' => 'Details for #2' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        issues = [base_issue, details1, other_issue, details2]
        result = validator.find_following_details_issues(issues, 0, base_location)

        expect(result.length).to eq(1)
        expect(result).to include(details1)
        expect(result).to_not include(details2)
      end

      it 'stops at Details message with different location' do
        base_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'ERROR', 'location' => base_location, 'message' => 'Base',
                       'messageId' => 'Reference_REF_CantMatchChoice' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        details1 = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => base_location, 'message' => 'Details for #1' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        details_other_location = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'INFO', 'location' => 'Coverage.payor[1]', 'message' => 'Details for #2' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        issues = [base_issue, details1, details_other_location]
        result = validator.find_following_details_issues(issues, 0, base_location)

        expect(result.length).to eq(1)
        expect(result).to include(details1)
        expect(result).to_not include(details_other_location)
      end

      it 'returns empty array when no following Details issues exist' do
        base_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'ERROR', 'location' => base_location, 'message' => 'Base',
                       'messageId' => 'Reference_REF_CantMatchChoice' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        other_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'ERROR', 'location' => 'Patient.name', 'message' => 'Other' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        issues = [base_issue, other_issue]
        result = validator.find_following_details_issues(issues, 0, base_location)

        expect(result).to be_empty
      end

      it 'returns empty array when base issue is last in array' do
        base_issue = Inferno::DSL::FHIRResourceValidation::ValidatorIssue.new(
          raw_issue: { 'level' => 'ERROR', 'location' => base_location, 'message' => 'Base',
                       'messageId' => 'Reference_REF_CantMatchChoice' },
          resource: resource,
          slice_info: [],
          filtered: false
        )

        issues = [base_issue]
        result = validator.find_following_details_issues(issues, 0, base_location)

        expect(result).to be_empty
      end
    end
  end
end
