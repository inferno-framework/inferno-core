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
              end.to raise_error(Inferno::Exceptions::ErrorInValidatorException, /Timeout while connecting/)

              expect(runnable.messages.last[:message]).to include('Timeout')
            end

            it 'handles SSL errors' do
              allow(validator).to receive(:call_validator).and_raise(
                Faraday::SSLError.new('Self-signed certificate in certificate chain')
              )

              expect do
                validator.resource_is_valid?(resource, profile_url, runnable)
              end.to raise_error(Inferno::Exceptions::ErrorInValidatorException, /SSL error/)

              expect(runnable.messages.last[:message]).to include('Self-signed')
            end

            it 'handles server 400s' do
              allow(validator).to receive(:call_validator).and_raise(
                Faraday::ClientError.new('404 Not Found')
              )

              expect do
                validator.resource_is_valid?(resource, profile_url, runnable)
              end.to raise_error(Inferno::Exceptions::ErrorInValidatorException, /Client error \(4xx\)/)

              expect(runnable.messages.last[:message]).to include('404')
            end

            it 'handles server 500s' do
              allow(validator).to receive(:call_validator).and_raise(
                Faraday::ServerError.new('500 Server Error')
              )

              expect do
                validator.resource_is_valid?(resource, profile_url, runnable)
              end.to raise_error(Inferno::Exceptions::ErrorInValidatorException, /Server error \(5xx\)/)

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
          stub_request(:post, "#{validation_url}/validate")
            .with(body: wrapped_resource_string)
            .to_return(
              status: 500,
              body: "<html><body>Internal Server Error: content#{0.chr} with non-printable#{1.chr} characters</body></html>" # rubocop:disable Layout/LineLength
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
end
