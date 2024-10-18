RSpec.describe Inferno::DSL::Assertions do
  let(:klass) do
    Class.new(Inferno::Entities::Test) do
      validator { url(ENV.fetch('VALIDATOR_URL')) }
    end.new
  end
  let(:error_outcome) do
    FHIR::OperationOutcome.new(
      issue: [{
        severity: 'error',
        expression: 'EXPRESSION',
        details: {
          text: 'TEXT'
        }
      }]
    )
  end
  let(:success_outcome) { FHIR::OperationOutcome.new }
  let(:outcome_with_messages) do
    FHIR::OperationOutcome.new(
      issue: [
        {
          severity: 'warning',
          expression: 'W_EXPRESSION',
          details: {
            text: 'W_TEXT'
          }
        },
        {
          severity: 'information',
          expression: 'I_EXPRESSION',
          details: {
            text: 'I_TEXT'
          }
        }
      ]
    )
  end
  let(:assertion_exception) { Inferno::Exceptions::AssertionException }
  let(:validation_url) { "#{ENV.fetch('VALIDATOR_URL')}/validate" }
  let(:patient_resource) { FHIR::Patient.new(id: SecureRandom.uuid) }
  let(:care_plan_resource) { FHIR::CarePlan.new(id: SecureRandom.uuid) }
  let(:profile_url) { 'PROFILE_URL' }

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
            .with(query: { profile: FHIR::Definitions.resource_definition('Patient').url })
            .with(body: patient_resource.source_contents)
            .to_return(status: 200, body: success_outcome.to_json)

        klass.assert_valid_resource(resource: patient_resource)

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when no resource is provided' do
      it 'uses its own resource' do
        allow(klass).to receive(:resource).and_return(patient_resource)
        validation_request =
          stub_request(:post, validation_url)
            .with(query: { profile: FHIR::Definitions.resource_definition('Patient').url })
            .with(body: patient_resource.source_contents)
            .to_return(status: 200, body: success_outcome.to_json)

        klass.assert_valid_resource

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when no profile_url is provided' do
      it "uses the resource's base profile" do
        validation_request =
          stub_request(:post, validation_url)
            .with(query: { profile: FHIR::Definitions.resource_definition('Patient').url })
            .with(body: patient_resource.source_contents)
            .to_return(status: 200, body: success_outcome.to_json)

        klass.assert_valid_resource(resource: patient_resource)

        expect(validation_request).to have_been_made.once
      end

      it 'uses an appropriate error message' do
        stub_request(:post, validation_url)
          .with(query: { profile: FHIR::Definitions.resource_definition('Patient').url })
          .with(body: patient_resource.source_contents)
          .to_return(status: 200, body: error_outcome.to_json)

        expect { klass.assert_valid_resource(resource: patient_resource) }.to(
          raise_error(assertion_exception, 'Resource does not conform to the base Patient profile.')
        )
      end
    end

    context 'when a profile_url is provided' do
      it 'uses the provided profile_url' do
        validation_request =
          stub_request(:post, validation_url)
            .with(query: { profile: profile_url })
            .with(body: patient_resource.source_contents)
            .to_return(status: 200, body: success_outcome.to_json)

        klass.assert_valid_resource(resource: patient_resource, profile_url:)

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when the resource is invalid' do
      it 'raises an exception' do
        stub_request(:post, validation_url)
          .with(query: { profile: profile_url })
          .with(body: patient_resource.source_contents)
          .to_return(status: 200, body: error_outcome.to_json)

        expect { klass.assert_valid_resource(resource: patient_resource, profile_url:) }.to(
          raise_error(assertion_exception, klass.invalid_resource_message(patient_resource, profile_url))
        )
      end

      it 'adds an error message' do
        stub_request(:post, validation_url)
          .with(query: { profile: profile_url })
          .with(body: patient_resource.source_contents)
          .to_return(status: 200, body: error_outcome.to_json)

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
            .with(query: { profile: profile_url })
            .with(body: patient_resource.source_contents)
            .to_return(status: 200, body: outcome_with_messages.to_json)

        klass.assert_valid_resource(resource: patient_resource, profile_url:)

        expect(validation_request).to have_been_made.once
      end

      it 'adds warning/info messages' do
        stub_request(:post, validation_url)
          .with(query: { profile: profile_url })
          .with(body: patient_resource.source_contents)
          .to_return(status: 200, body: outcome_with_messages.to_json)

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
          .with(query: { profile: profile_url })
          .with(body: patient_resource.source_contents)
          .to_return(status: 200, body: outcome_with_messages.to_json)

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
        validation_requests =
          [
            stub_request(:post, validation_url)
              .with(query: { profile: FHIR::Definitions.resource_definition('Patient').url })
              .with(body: patient_resource.source_contents)
              .to_return(status: 200, body: success_outcome.to_json),
            stub_request(:post, validation_url)
              .with(query: { profile: FHIR::Definitions.resource_definition('CarePlan').url })
              .with(body: care_plan_resource.source_contents)
              .to_return(status: 200, body: error_outcome.to_json)
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

        validation_requests =
          [
            stub_request(:post, validation_url)
              .with(query: { profile: FHIR::Definitions.resource_definition('Patient').url })
              .with(body: patient_resource.source_contents)
              .to_return(status: 200, body: success_outcome.to_json),
            stub_request(:post, validation_url)
              .with(query: { profile: FHIR::Definitions.resource_definition('CarePlan').url })
              .with(body: care_plan_resource.source_contents)
              .to_return(status: 200, body: success_outcome.to_json)
          ]

        klass.assert_valid_bundle_entries

        expect(validation_requests).to all(have_been_made.once)
      end
    end

    context 'when no resource_types hash is provided' do
      it 'validates all entries against their base profiles' do
        validation_requests =
          [
            stub_request(:post, validation_url)
              .with(query: { profile: FHIR::Definitions.resource_definition('Patient').url })
              .with(body: patient_resource.source_contents)
              .to_return(status: 200, body: success_outcome.to_json),
            stub_request(:post, validation_url)
              .with(query: { profile: FHIR::Definitions.resource_definition('CarePlan').url })
              .with(body: care_plan_resource.source_contents)
              .to_return(status: 200, body: success_outcome.to_json)
          ]

        klass.assert_valid_bundle_entries(bundle:)

        expect(validation_requests).to all(have_been_made.once)
      end
    end

    context 'when a resource_types string is provided' do
      it 'only validates that resource_type against its base profile' do
        validation_request =
          stub_request(:post, validation_url)
            .with(query: { profile: FHIR::Definitions.resource_definition('CarePlan').url })
            .with(body: care_plan_resource.source_contents)
            .to_return(status: 200, body: success_outcome.to_json)

        klass.assert_valid_bundle_entries(bundle:, resource_types: 'CarePlan')

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when a resource_types array is provided' do
      it 'only validates those resource_types against their base profiles' do
        validation_request =
          stub_request(:post, validation_url)
            .with(query: { profile: FHIR::Definitions.resource_definition('CarePlan').url })
            .with(body: care_plan_resource.source_contents)
            .to_return(status: 200, body: success_outcome.to_json)

        klass.assert_valid_bundle_entries(bundle:, resource_types: ['CarePlan'])

        expect(validation_request).to have_been_made.once
      end
    end

    context 'when a resource_types hash is provided' do
      it 'only validates those types against the provided profile or the base profile if no profile provided' do
        patient_profile = 'PATIENT_PROFILE'
        validation_requests =
          [
            stub_request(:post, validation_url)
              .with(query: { profile: patient_profile })
              .with(body: patient_resource.source_contents)
              .to_return(status: 200, body: success_outcome.to_json),
            stub_request(:post, validation_url)
              .with(query: { profile: FHIR::Definitions.resource_definition('CarePlan').url })
              .with(body: care_plan_resource.source_contents)
              .to_return(status: 200, body: success_outcome.to_json)
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
end
