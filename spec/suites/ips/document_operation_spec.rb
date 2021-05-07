RSpec.describe IPS::DocumentOperation do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('ips') }
  let(:group) { suite.groups.first.groups.first }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'ips') }
  let(:url) { 'http://example.com/fhir' }
  let(:error_outcome) { FHIR::OperationOutcome.new(issue: [{ severity: 'error' }]) }
  let(:base_capability_params) do
    {
      fhirVersion: '4.0.1'
    }
  end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable, inputs)
    Inferno::Repositories::TestRuns.new.results_for_test_run(test_run.id)
  end

  describe 'Capability test' do
    let(:test) { group.tests.first }

    it 'passes if a CapabilityStatement which supports the document operation is received' do
      resource = FHIR::CapabilityStatement.new(
        base_capability_params.merge(
          rest: [
            {
              resource: [
                {
                  type: 'Composition',
                  operation: [{ definition: 'http://hl7.org/fhir/OperationDefinition/Composition-document' }]
                }
              ]
            }
          ]
        )
      )
      stubbed_request =
        stub_request(:get, "#{url}/metadata")
          .to_return(status: 200, body: resource.to_json)

      result = run(test, { url: url }).first

      expect(stubbed_request).to have_been_made.once
      expect(result.result).to eq('pass')
    end

    it 'fails if a non-200 status code is received' do
      stubbed_request =
        stub_request(:get, "#{url}/metadata")
          .to_return(status: 500)

      result = run(test, { url: url }).first

      expect(stubbed_request).to have_been_made.at_least_once
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/200/)
    end

    describe 'Operation test' do
      let(:test) { group.tests[1] }
      let(:composition_id) { 'abc123' }

      it 'passes if a Bundle is received containing all resources referenced in the Composition' do
        stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
          .with(query: hash_including({}))
          .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

        composition = FHIR::Composition.new(
          id: composition_id,
          section: [
            { entry: [{ reference: 'Patient/123' }] },
            { entry: [{ reference: 'Condition/456' }] }
          ]
        )
        bundle = FHIR::Bundle.new(
          entry: [
            { resource: FHIR::Patient.new(id: '123') },
            { resource: FHIR::Condition.new(id: '456') }
          ]
        )
        read_request =
          stub_request(:get, "#{url}/Composition/#{composition_id}")
            .to_return(status: 200, body: composition.to_json)
        operation_request =
          stub_request(:post, "#{url}/Composition/#{composition_id}/$document")
            .with(query: { persist: true })
            .to_return(status: 200, body: bundle.to_json)

        result = run(test, { url: url, composition_id: composition_id }).first

        expect(result.result).to eq('pass')
        expect(read_request).to have_been_made.once
        expect(operation_request).to have_been_made.once
      end

      it 'fails if the Composition is invalid' do
        stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
          .with(query: hash_including({}))
          .to_return(status: 200, body: error_outcome.to_json)

        composition = FHIR::Composition.new(id: composition_id)
        read_request =
          stub_request(:get, "#{url}/Composition/#{composition_id}")
            .to_return(status: 200, body: composition.to_json)

        result = run(test, { url: url, composition_id: composition_id }).first

        expect(result.result).to eq('fail')
        expect(read_request).to have_been_made.once
        expect(result.result_message).to match(/Resource does not conform/)
      end

      it 'fails if the Bundle does not contain all resources referenced in the Composition' do
        stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
          .with(query: hash_including({}))
          .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

        composition = FHIR::Composition.new(
          id: composition_id,
          section: [
            { entry: [{ reference: 'Patient/123' }] },
            { entry: [{ reference: 'Condition/456' }] }
          ]
        )
        bundle = FHIR::Bundle.new(
          entry: [
            { resource: FHIR::Patient.new(id: '123') }
          ]
        )
        read_request =
          stub_request(:get, "#{url}/Composition/#{composition_id}")
            .to_return(status: 200, body: composition.to_json)
        operation_request =
          stub_request(:post, "#{url}/Composition/#{composition_id}/$document")
            .with(query: { persist: true })
            .to_return(status: 200, body: bundle.to_json)

        result = run(test, { url: url, composition_id: composition_id }).first

        expect(result.result).to eq('fail')
        expect(read_request).to have_been_made.once
        expect(operation_request).to have_been_made.once
        expect(result.result_message).to match(%r{resources were missing.*Condition/456})
      end
    end
  end

  describe 'Bundle test' do
    let(:test) { group.tests[2] }

    it 'passes if a valid Bundle was received' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      resource = FHIR::Bundle.new

      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )
      result = run(test).first

      expect(result.result).to eq('pass')
    end

    it 'skips if a Bundle has not been received' do
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: FHIR::Patient.new.to_json
      )

      result = run(test).first

      expect(result.result).to eq('skip')
    end

    it 'fails if the Bundle is invalid' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: error_outcome.to_json)

      resource = FHIR::Bundle.new
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Resource does not conform/)
    end
  end

  describe 'Composition test' do
    let(:test) { group.tests[3] }

    it 'passes if the first Bundle entry is a valid Composition' do
      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::Composition.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      result = run(test).first

      expect(result.result).to eq('pass')
    end

    it 'skips if a Bundle has not been received' do
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: FHIR::Patient.new.to_json
      )

      result = run(test).first

      expect(result.result).to eq('skip')
    end

    it 'fails if the first Bundle entry is not a valid Composition' do
      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::Patient.new }, { resource: FHIR::Composition.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/first entry/)
    end

    it 'fails if the Composition is invalid' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: error_outcome.to_json)

      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::Composition.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Resource does not conform/)
    end
  end

  describe 'MedicationStatement test' do
    let(:test) { group.tests[4] }

    it 'passes if the Bundle contains a valid MedicationStatement' do
      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::MedicationStatement.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      result = run(test).first

      expect(result.result).to eq('pass')
    end

    it 'skips if a Bundle has not been received' do
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: FHIR::Patient.new.to_json
      )

      result = run(test).first

      expect(result.result).to eq('skip')
    end

    it 'fails if the Bundle does not contain a MedicationStatement' do
      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::Patient.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/does not contain/)
    end

    it 'fails if the MedicationStatement is invalid' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: error_outcome.to_json)

      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::MedicationStatement.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/bundle entries are invalid/)
    end
  end

  describe 'AllergyIntolerance test' do
    let(:test) { group.tests[5] }

    it 'passes if the Bundle contains a valid AllergyIntolerance' do
      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::AllergyIntolerance.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      result = run(test).first

      expect(result.result).to eq('pass')
    end

    it 'skips if a Bundle has not been received' do
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: FHIR::Patient.new.to_json
      )

      result = run(test).first

      expect(result.result).to eq('skip')
    end

    it 'fails if the Bundle does not contain a AllergyIntolerance' do
      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::Patient.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/does not contain/)
    end

    it 'fails if the AllergyIntolerance is invalid' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: error_outcome.to_json)

      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::AllergyIntolerance.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/bundle entries are invalid/)
    end
  end

  describe 'Condition test' do
    let(:test) { group.tests[6] }

    it 'passes if the Bundle contains a valid Condition' do
      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::Condition.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      result = run(test).first

      expect(result.result).to eq('pass')
    end

    it 'skips if a Bundle has not been received' do
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: FHIR::Patient.new.to_json
      )

      result = run(test).first

      expect(result.result).to eq('skip')
    end

    it 'fails if the Bundle does not contain a Condition' do
      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::Patient.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/does not contain/)
    end

    it 'fails if the Condition is invalid' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: error_outcome.to_json)

      resource = FHIR::Bundle.new(entry: [{ resource: FHIR::Condition.new }])
      repo_create(
        :request,
        name: :document_operation,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/bundle entries are invalid/)
    end
  end
end
