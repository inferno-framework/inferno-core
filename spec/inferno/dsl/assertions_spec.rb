require 'ostruct'

RSpec.describe Inferno::DSL::Assertions do
  let(:klass) do
    Class.new(Inferno::Entities::Test) do
      fhir_resource_validator {} # rubocop:disable Lint/EmptyBlock
    end.new
  end
  let(:error_response) do
    {
      outcomes: [
        {
          issues: [
            {
              level: 'error',
              location: 'EXPRESSION',
              message: 'TEXT'
            }
          ]
        }
      ]
    }
  end
  let(:success_response) { { outcomes: [{}] } }
  let(:response_with_messages) do
    {
      outcomes: [
        {
          issues: [
            {
              level: 'warning',
              location: 'W_EXPRESSION',
              message: 'W_TEXT'
            },
            {
              level: 'information',
              location: 'I_EXPRESSION',
              message: 'I_TEXT'
            }
          ]
        }
      ]
    }
  end
  let(:assertion_exception) { Inferno::Exceptions::AssertionException }
  let(:validation_url) { "#{ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')}/validate" }
  let(:patient_resource) { FHIR::Patient.new(id: SecureRandom.uuid) }
  let(:care_plan_resource) { FHIR::CarePlan.new(id: SecureRandom.uuid) }
  let(:profile_url) { 'PROFILE_URL' }

  def validation_body(resource, profile_url)
    {
      validatorContext: {
        sv: '4.0.1',
        doNative: false,
        extensions: ['any'],
        disableDefaultResourceFetcher: true,
        profiles: [profile_url]
      },
      filesToValidate: [
        {
          fileName: "#{resource.resourceType}/#{resource.id}.json",
          fileContent: resource.source_contents,
          fileType: 'json'
        }
      ],
      sessionId: nil
    }
  end

  describe '#assert_response_status' do
    context 'when a response is provided' do
      context 'with a single status' do
        it 'does not raise an exception if the response matches the status' do
          expect do
            klass.assert_response_status(200, response: { status: 200 })
          end.to_not raise_error
        end

        it 'raises an exception if the response does not match the status' do
          error_message = klass.bad_response_status_message(201, 200)
          expect { klass.assert_response_status(201, response: { status: 200 }) }.to(
            raise_error(assertion_exception, error_message)
          )
        end
      end

      context 'with an array of statuses' do
        it 'does not raise an exception if the response matches a status' do
          expect do
            klass.assert_response_status([100, 200, 300], response: { status: 200 })
          end.to_not raise_error
        end

        it 'raises an exception if the response does not match the status' do
          error_message = klass.bad_response_status_message([101, 201], 200)
          expect { klass.assert_response_status([101, 201], response: { status: 200 }) }.to(
            raise_error(assertion_exception, error_message)
          )
        end
      end
    end

    context 'when a request is provided' do
      it 'uses that request' do
        def klass.request
          OpenStruct.new(
            response: { status: 201 }
          )
        end

        request_arg = OpenStruct.new(response: { status: 200 })

        error_message = klass.bad_response_status_message(201, 200)
        expect { klass.assert_response_status(201, request: request_arg) }.to(
          raise_error(assertion_exception, error_message)
        )
      end
    end

    context 'when no response is provided' do
      it "uses the response from the test's request" do
        def klass.request
          OpenStruct.new(
            response: { status: 200 }
          )
        end

        error_message = klass.bad_response_status_message(201, 200)
        expect { klass.assert_response_status(201) }.to(
          raise_error(assertion_exception, error_message)
        )
      end
    end
  end

  describe '#assert_resource_type' do
    context 'when a resource is provided' do
      it 'does not raise an exception if the resource matches the type' do
        expect do
          klass.assert_resource_type('CarePlan', resource: care_plan_resource)
        end.to_not raise_error
      end

      it 'raises an exception if the resource does not match the type' do
        error_message = klass.bad_resource_type_message('CarePlan', 'Patient')
        expect { klass.assert_resource_type('CarePlan', resource: patient_resource) }.to(
          raise_error(assertion_exception, error_message)
        )
      end
    end

    context 'when no resource is provided' do
      it 'uses its own resource' do
        allow(klass).to receive(:resource).and_return(patient_resource)

        error_message = klass.bad_resource_type_message('CarePlan', 'Patient')
        expect { klass.assert_resource_type('CarePlan') }.to(
          raise_error(assertion_exception, error_message)
        )
      end
    end
  end

  describe '#assert_valid_resource' do
    context 'when a resource is provided' do
      it 'does not raise an exception if the resource is valid' do
        validation_request =
          stub_request(:post, validation_url)
            .with(body: validation_body(patient_resource, FHIR::Definitions.resource_definition('Patient').url))
            .to_return(status: 200, body: success_response.to_json)

        klass.assert_valid_resource(resource: patient_resource)

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when no resource is provided' do
      it 'uses its own resource' do
        allow(klass).to receive(:resource).and_return(patient_resource)
        validation_request =
          stub_request(:post, validation_url)
            .with(body: validation_body(patient_resource, FHIR::Definitions.resource_definition('Patient').url))
            .to_return(status: 200, body: success_response.to_json)

        klass.assert_valid_resource

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when no profile_url is provided' do
      it "uses the resource's base profile" do
        validation_request =
          stub_request(:post, validation_url)
            .with(body: validation_body(patient_resource, FHIR::Definitions.resource_definition('Patient').url))
            .to_return(status: 200, body: success_response.to_json)

        klass.assert_valid_resource(resource: patient_resource)

        expect(validation_request).to have_been_made.once
      end

      it 'uses an appropriate error message' do
        stub_request(:post, validation_url)
          .to_return(status: 200, body: error_response.to_json)

        expect { klass.assert_valid_resource(resource: patient_resource) }.to(
          raise_error(assertion_exception, 'Resource does not conform to the base Patient profile.')
        )
      end
    end

    context 'when a profile_url is provided' do
      it 'uses the provided profile_url' do
        validation_request =
          stub_request(:post, validation_url)
            .with(body: validation_body(patient_resource, profile_url))
            .to_return(status: 200, body: success_response.to_json)

        klass.assert_valid_resource(resource: patient_resource, profile_url:)

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when the resource is invalid' do
      it 'raises an exception' do
        stub_request(:post, validation_url)
          .to_return(status: 200, body: error_response.to_json)

        expect { klass.assert_valid_resource(resource: patient_resource, profile_url:) }.to(
          raise_error(assertion_exception, klass.invalid_resource_message(patient_resource, profile_url))
        )
      end

      it 'adds an error message' do
        stub_request(:post, validation_url)
          .to_return(status: 200, body: error_response.to_json)

        expect { klass.assert_valid_resource(resource: patient_resource, profile_url:) }.to(
          raise_error(assertion_exception, klass.invalid_resource_message(patient_resource, profile_url))
        )

        error_message = klass.messages.find { |message| message[:type] == 'error' }
        expect(error_message).to be_present
        expect(error_message[:message]).to eq("Patient/#{patient_resource.id}: EXPRESSION: TEXT")
      end
    end

    context 'when non-error issues are present' do
      it 'does not raise an exception' do
        validation_request =
          stub_request(:post, validation_url)
            .to_return(status: 200, body: response_with_messages.to_json)

        klass.assert_valid_resource(resource: patient_resource, profile_url:)

        expect(validation_request).to have_been_made.once
      end

      it 'adds warning/info messages' do
        stub_request(:post, validation_url)
          .to_return(status: 200, body: response_with_messages.to_json)

        klass.assert_valid_resource(resource: patient_resource, profile_url:)

        warning_message = klass.messages.find { |message| message[:type] == 'warning' }

        expect(warning_message).to be_present
        expect(warning_message[:message]).to eq("Patient/#{patient_resource.id}: W_EXPRESSION: W_TEXT")

        info_message = klass.messages.find { |message| message[:type] == 'info' }

        expect(info_message).to be_present
        expect(info_message[:message]).to eq("Patient/#{patient_resource.id}: I_EXPRESSION: I_TEXT")
      end

      it 'filters messages based on the exclude_message block' do
        filter = proc { |message| message.type == 'info' }
        allow(klass.class.find_validator(:default)).to receive(:exclude_message).and_return(filter)

        stub_request(:post, validation_url)
          .to_return(status: 200, body: response_with_messages.to_json)

        klass.assert_valid_resource(resource: patient_resource, profile_url:)

        warning_message = klass.messages.find { |message| message[:type] == 'warning' }

        expect(warning_message).to be_present
        expect(warning_message[:message]).to eq("Patient/#{patient_resource.id}: W_EXPRESSION: W_TEXT")

        info_message = klass.messages.find { |message| message[:type] == 'info' }

        expect(info_message).to be_nil
      end
    end
  end

  describe '#assert_valid_bundle_entries' do
    let(:bundle) do
      FHIR::Bundle.new(
        entry: [
          {
            resource: patient_resource
          },
          {
            resource: care_plan_resource
          }
        ]
      )
    end

    context 'when a resource is invalid' do
      it 'raises an exception' do
        patient_validation_body =
          validation_body(patient_resource, FHIR::Definitions.resource_definition('Patient').url)
        care_plan_validation_body =
          validation_body(care_plan_resource, FHIR::Definitions.resource_definition('CarePlan').url)
        validation_requests =
          [
            stub_request(:post, validation_url)
              .with(body: patient_validation_body)
              .to_return(status: 200, body: success_response.to_json),
            stub_request(:post, validation_url)
              .with(body: care_plan_validation_body)
              .to_return(status: 200, body: error_response.to_json)
          ]

        expect { klass.assert_valid_bundle_entries(bundle:) }.to(
          raise_error(assertion_exception, klass.invalid_bundle_entries_message([care_plan_resource]))
        )

        expect(validation_requests).to all(have_been_made.once)
      end
    end

    context 'when no bundle is provided' do
      it "uses the class's resource" do
        allow(klass).to receive(:resource).and_return(bundle)
        patient_validation_body =
          validation_body(patient_resource, FHIR::Definitions.resource_definition('Patient').url)
        care_plan_validation_body =
          validation_body(care_plan_resource, FHIR::Definitions.resource_definition('CarePlan').url)

        validation_requests =
          [
            stub_request(:post, validation_url)
              .with(body: patient_validation_body)
              .to_return(status: 200, body: success_response.to_json),
            stub_request(:post, validation_url)
              .with(body: care_plan_validation_body)
              .to_return(status: 200, body: success_response.to_json)
          ]

        klass.assert_valid_bundle_entries

        expect(validation_requests).to all(have_been_made.once)
      end
    end

    context 'when no resource_types hash is provided' do
      it 'validates all entries against their base profiles' do
        patient_validation_body =
          validation_body(patient_resource, FHIR::Definitions.resource_definition('Patient').url)
        care_plan_validation_body =
          validation_body(care_plan_resource, FHIR::Definitions.resource_definition('CarePlan').url)
        validation_requests =
          [
            stub_request(:post, validation_url)
              .with(body: patient_validation_body)
              .to_return(status: 200, body: success_response.to_json),
            stub_request(:post, validation_url)
              .with(body: care_plan_validation_body)
              .to_return(status: 200, body: success_response.to_json)
          ]

        klass.assert_valid_bundle_entries(bundle:)

        expect(validation_requests).to all(have_been_made.once)
      end
    end

    context 'when a resource_types string is provided' do
      it 'only validates that resource_type against its base profile' do
        care_plan_validation_body =
          validation_body(care_plan_resource, FHIR::Definitions.resource_definition('CarePlan').url)
        validation_request =
          stub_request(:post, validation_url)
            .with(body: care_plan_validation_body)
            .to_return(status: 200, body: success_response.to_json)

        klass.assert_valid_bundle_entries(bundle:, resource_types: 'CarePlan')

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when a resource_types array is provided' do
      it 'only validates those resource_types against their base profiles' do
        care_plan_validation_body =
          validation_body(care_plan_resource, FHIR::Definitions.resource_definition('CarePlan').url)
        validation_request =
          stub_request(:post, validation_url)
            .with(body: care_plan_validation_body)
            .to_return(status: 200, body: success_response.to_json)

        klass.assert_valid_bundle_entries(bundle:, resource_types: ['CarePlan'])

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when a resource_types hash is provided' do
      it 'only validates those types against the provided profile or the base profile if no profile provided' do
        patient_profile = 'PATIENT_PROFILE'
        patient_validation_body =
          validation_body(patient_resource, patient_profile)
        care_plan_validation_body =
          validation_body(care_plan_resource, FHIR::Definitions.resource_definition('CarePlan').url)
        validation_requests =
          [
            stub_request(:post, validation_url)
              .with(body: patient_validation_body)
              .to_return(status: 200, body: success_response.to_json),
            stub_request(:post, validation_url)
              .with(body: care_plan_validation_body)
              .to_return(status: 200, body: success_response.to_json)
          ]

        klass.assert_valid_bundle_entries(
          bundle:,
          resource_types: { patient: patient_profile, care_plan: nil }
        )

        expect(validation_requests).to all(have_been_made.once)
      end
    end
  end

  describe '#assert_response_content_type' do
    it 'raises an exception when no Content-Type header is present' do
      request = repo_create(:request)
      expect { klass.assert_response_content_type('abc', request:) }.to(
        raise_error(assertion_exception, klass.no_content_type_message)
      )
    end

    it 'raises an exception when the Content-Type header does not match' do
      request = repo_create(:request, headers: [{ type: 'response', name: 'Content-Type', value: 'xyz' }])
      expect { klass.assert_response_content_type('abc', request:) }.to(
        raise_error(assertion_exception, klass.bad_content_type_message('abc', 'xyz'))
      )
    end

    it 'does not raise an exception when the Content-Type headers starts with the supplied value' do
      request = repo_create(:request, headers: [{ type: 'response', name: 'Content-Type', value: 'abcdef' }])
      expect { klass.assert_response_content_type('abc', request:) }.to_not raise_error
    end
  end

  describe '#assert_must_support_elements_present' do
    let(:test_klass) do
      uscore3_package = File.expand_path('../../fixtures/uscore311.tgz', __dir__)
      Class.new(Inferno::Entities::Test) do
        fhir_resource_validator { igs(uscore3_package) }
      end.new
    end

    # https://www.hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-medication.html
    # Note the only MS element is Medication.code
    let(:uscore_medication) do
      'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'
    end

    let(:medication) do
      FHIR::Medication.new(
        meta: { profile: ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'] },
        status: 'active',
        code: {
          coding: [{
            system: 'http://www.nlm.nih.gov/research/umls/rxnorm',
            code: '206765',
            display: 'Prinivil 10 MG Oral Tablet'
          }],
          text: 'lisinopril oral 10 mg'
        }
      )
    end

    context 'with default metadata' do
      it 'raises an exception when MS elements are missing' do
        medication.code = nil
        expect { test_klass.assert_must_support_elements_present([medication], uscore_medication) }.to(
          raise_error(assertion_exception, 'Could not find code in the 1 provided resource(s)')
        )
      end

      it 'passes when all MS elements are present' do
        expect { test_klass.assert_must_support_elements_present([medication], uscore_medication) }.to_not raise_error
      end
    end

    context 'with modified metadata' do
      it 'raises an exception when MS elements are missing' do
        medication.status = nil
        expect do
          test_klass.assert_must_support_elements_present([medication], uscore_medication) do |metadata|
            metadata.must_supports[:elements] << { path: 'status' }
          end
        end.to(
          raise_error(assertion_exception, 'Could not find status in the 1 provided resource(s)')
        )
      end

      it 'passes when all MS elements are present' do
        expect do
          test_klass.assert_must_support_elements_present([medication], uscore_medication) do |metadata|
            metadata.must_supports[:elements] << { path: 'status' }
          end
        end.to_not raise_error
      end
    end

    context 'with provided metadata' do
      let(:metadata) do
        OpenStruct.new({
                         must_supports: {
                           extensions: [],
                           slices: [],
                           elements: [
                             { path: 'code' },
                             { path: 'status' }
                           ]
                         }
                       })
      end

      it 'raises an exception when MS elements are missing' do
        medication.status = nil
        expect { test_klass.assert_must_support_elements_present([medication], profile_url, metadata:) }.to(
          raise_error(assertion_exception, 'Could not find status in the 1 provided resource(s)')
        )
      end

      it 'passes when all MS elements are present' do
        expect do
          test_klass.assert_must_support_elements_present([medication], profile_url, metadata:)
        end.to_not raise_error
      end
    end

    it 'raises an exception on bad profile URL' do
      profile_url = 'http://example.com/badprofile'
      expect { test_klass.assert_must_support_elements_present([], profile_url) }.to(
        raise_error(RuntimeError, "Unable to find profile #{profile_url} in any IG defined for validator default")
      )
    end
  end
end
