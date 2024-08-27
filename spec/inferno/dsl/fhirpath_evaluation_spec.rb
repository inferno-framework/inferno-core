RSpec.describe Inferno::DSL::FhirpathEvaluation do
  let(:evaluator_url) { 'http://example.com' }
  let(:evaluator) do
    Inferno::DSL::FhirpathEvaluation::Evaluator.new(evaluator_url)
  end
  let(:runnable) { Inferno::Entities::Test.new }
  let(:patient) do
    FHIR::Patient.new(
      id: '1234',
      name: [FHIR::HumanName.new(family: 'Example',
                                 given: ['patient', 'sample'])],
      gender: 'male',
      birthDate: '1974-01-01'
    )
  end
  let(:fhirpath_expression) { 'Patient.name.given' }
  let(:response_body) do
    [
      { type: 'string', element: 'patient' },
      { type: 'string', element: 'sample' }
    ].to_json
  end
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:suite) do
    Class.new(Inferno::Entities::TestSuite) do
      fhirpath_evaluator url: 'http://default.com'

      fhirpath_evaluator name: :custom, url: 'http://custom.com'
    end
  end

  describe '#evaluate_fhirpath' do
    context 'when the FHIRPath service responds successfully' do
      it 'parses the response body and returns the evaluated result' do
        stub_request(:post, "#{evaluator_url}/evaluate?path=#{fhirpath_expression}")
          .with(body: patient.to_json, headers:)
          .to_return(status: 200, body: response_body)

        result = evaluator.evaluate_fhirpath(patient,
                                             fhirpath_expression, runnable)
        expect(result).to eq(JSON.parse(response_body))
      end
    end

    context 'when the FHIRPath service responds with an error' do
      it 'raises an ErrorInFhirpathException and adds an error message to the runnable' do
        stub_request(:post, "#{evaluator_url}/evaluate?path=#{fhirpath_expression}")
          .with(body: patient.to_json, headers:)
          .to_return(status: 500, body: 'Internal Server Error')

        expect do
          evaluator.evaluate_fhirpath(patient, fhirpath_expression,
                                      runnable)
        end.to raise_error(
          Inferno::Exceptions::ErrorInFhirpathException, /FHIRPath service call failed/
        )
        expect(runnable.messages.last[:type]).to eq('error')
        expect(runnable.messages.last[:message]).to match(/FHIRPath service Response: HTTP 500/)
      end
    end

    context 'when the FHIRPath service response is not in JSON format' do
      it 'raises an ErrorInFhirpathException for invalid JSON format and adds an error message to the runnable' do
        stub_request(:post, "#{evaluator_url}/evaluate?path=#{fhirpath_expression}")
          .with(body: patient.to_json, headers:)
          .to_return(status: 200, body: '{]')

        expect do
          evaluator.evaluate_fhirpath(patient, fhirpath_expression,
                                      runnable)
        end.to raise_error(
          Inferno::Exceptions::ErrorInFhirpathException, /Error occurred in the FHIRPath service/
        )
        expect(runnable.messages.last[:type]).to eq('error')
        expect(runnable.messages.last[:message]).to match(/Invalid FHIRPath service response format/)
      end
    end

    context 'when a connection error occurs' do
      it 'raises an ErrorInFhirpathException for connection failure' do
        stub_request(:post, "#{evaluator_url}/evaluate?path=#{fhirpath_expression}")
          .with(body: patient.to_json, headers:)
          .to_raise(Faraday::ConnectionFailed.new('Connection failed'))

        expect do
          evaluator.evaluate_fhirpath(patient, fhirpath_expression,
                                      runnable)
        end.to raise_error(
          Inferno::Exceptions::ErrorInFhirpathException, /Unable to connect to FHIRPath service/
        )
        expect(runnable.messages.last[:type]).to eq('error')
        expect(runnable.messages.last[:message]).to match(/Connection failed/)
      end
    end

    it 'removes non-printable characters from the response' do
      stub_request(:post, "#{evaluator_url}/evaluate?path=#{fhirpath_expression}")
        .with(body: patient.to_json, headers:)
        .to_return(
          status: 500,
          body: "Internal Server Error: content#{0.chr} with non-printable#{1.chr} characters"
        )

      expect do
        evaluator.evaluate_fhirpath(patient, fhirpath_expression, runnable)
      end.to raise_error(Inferno::Exceptions::ErrorInFhirpathException, /FHIRPath service call failed/)

      msg = runnable.messages.first[:message]
      expect(msg).to_not include(0.chr)
      expect(msg).to_not include(1.chr)
      expect(msg).to match(/Internal Server Error: content with non-printable characters/)
    end
  end
end
