class FHIRClientDSLTestClass
  include Inferno::DSL::FHIRClient
  include Inferno::DSL::HTTPClient
  extend Inferno::DSL::Configurable
  include Inferno::DSL::Results

  def test_session_id
    nil
  end

  fhir_client do
    url 'http://www.example.com/fhir'
  end

  fhir_client :client_with_bearer_token do
    url 'http://www.example.com/fhir'
    bearer_token 'some_token'
  end

  fhir_client :client_with_oauth_credentials do
    url 'http://www.example.com/fhir'
    oauth_credentials(
      Inferno::DSL::OAuthCredentials.new(
        access_token: 'ACCESS_TOKEN',
        token_url: 'http://example.com/token',
        refresh_token: 'REFRESH_TOKEN',
        expires_in: 3600
      )
    )
  end
end

RSpec.describe Inferno::DSL::FHIRClient do
  let(:group) { FHIRClientDSLTestClass.new }
  let(:base_url) { 'http://www.example.com/fhir' }
  let(:resource_id) { '123' }
  let(:resource) { FHIR::CarePlan.new(id: resource_id) }
  let(:default_client) { group.fhir_clients[:default] }
  let(:bundle) { FHIR::Bundle.new(entry: [{ resource: }]) }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }

  describe '#fhir_client' do
    context 'without an argument' do
      it 'returns the default FHIR client' do
        expect(group.fhir_client).to eq(default_client)
      end

      it 'raises an error if no default FHIR client has been created'
    end

    context 'with an argument' do
      it 'returns the specified FHIR client' do
        name = :other_client
        other_client = FHIR::Client.new('http://www.example.com/fhir/r4')
        group.fhir_clients[name] = other_client

        expect(group.fhir_client(name)).to eq(other_client)
      end

      it 'raises an error if the FHIR client is not known'
    end

    context 'with a base url that causes a non-TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:initialize)
          .and_raise(SocketError, 'not a TCP error')
      end

      it 'raises the error' do
        expect do
          group.fhir_client
        end.to raise_error(SocketError, 'not a TCP error')
      end
    end
  end

  describe '#fhir_operation' do
    let(:path) { 'abc' }
    let(:stub_operation_request) do
      stub_request(:post, "#{base_url}/#{path}")
        .to_return(status: 200, body: resource.to_json)
    end
    let(:stub_operation_get_request) do
      stub_request(:get, "#{base_url}/#{path}")
        .to_return(status: 200, body: resource.to_json)
    end

    before do
      stub_operation_request
      stub_operation_get_request
    end

    it 'performs a post' do
      group.fhir_operation(path)

      expect(stub_operation_request).to have_been_made.once
    end

    it 'performs a get' do
      group.fhir_operation(path, affects_state: false)

      expect(stub_operation_get_request).to have_been_made.once
    end

    it 'returns an Inferno::Entities::Request' do
      result = group.fhir_operation(path)

      expect(result).to be_a(Inferno::Entities::Request)
    end

    it 'adds the request to the list of requests' do
      result = group.fhir_operation(path)

      expect(group.requests).to include(result)
      expect(group.request).to eq(result)
    end

    context 'with a body of parameters' do
      p1 = FHIR::Parameters::Parameter.new
      p1.name = 'Param1'
      p1.valueBoolean = true

      p2 = FHIR::Parameters::Parameter.new
      p2.name = 'Param2'
      p2.valueString = 'zyx'

      p3 = FHIR::Parameters::Parameter.new
      p3.name = 'nonPrimParam'

      ratio = FHIR::Ratio.new
      ratio.numerator = FHIR::Quantity.new
      ratio.denominator = FHIR::Quantity.new
      p3.valueRatio = ratio

      it 'uses get when all parameters are primitive' do
        b = FHIR::Parameters.new
        b.parameter = [p1, p2]

        query_string = '?Param1=true&Param2=zyx'

        get_with_body_request_stub =
          stub_request(:get, "#{base_url}/#{path + query_string}")
            .to_return(status: 200, body: resource.to_json)

        group.fhir_operation(path, body: b, affects_state: false)

        expect(get_with_body_request_stub).to have_been_made.once
      end

      it 'prevents get when parameters are non-primitive' do
        b = FHIR::Parameters.new
        b.parameter = [p1, p3]
        expect do
          group.fhir_operation(path, body: b, affects_state: false)
        end.to raise_error(ArgumentError, 'Cannot use GET request with non-primitive datatype nonPrimParam')
      end
    end

    context 'with the client parameter' do
      it 'uses that client' do
        other_url = 'http://www.example.com/fhir/r4'
        group.fhir_clients[:other_client] = FHIR::Client.new(other_url)

        other_request_stub =
          stub_request(:post, "#{other_url}/#{path}")
            .to_return(status: 200, body: resource.to_json)

        group.fhir_operation(path, client: :other_client)

        expect(other_request_stub).to have_been_made
        expect(stub_operation_request).to_not have_been_made
      end
    end

    context 'with headers' do
      let(:client_with_header) do
        block =
          proc do
            url 'http://www.example.com/fhir'
            headers 'DefaultHeader' => 'ClientHeader'
          end
        Inferno::DSL::FHIRClientBuilder.new.build(group, block)
      end

      let(:stub_custom_header_request) do
        stub_request(:post, "#{base_url}/#{path}")
          .with(headers: { 'CustomHeader' => 'CustomTest' })
          .to_return(status: 200, body: resource.to_json)
      end

      let(:stub_default_header_request) do
        stub_request(:post, "#{base_url}/#{path}")
          .with(headers: { 'DefaultHeader' => 'ClientHeader' })
          .to_return(status: 200, body: resource.to_json)
      end

      let(:stub_custom_and_default_header_request) do
        stub_request(:post, "#{base_url}/#{path}")
          .with(headers: { 'DefaultHeader' => 'ClientHeader', 'CustomHeader' => 'CustomTest' })
          .to_return(status: 200, body: resource.to_json)
      end

      it 'as custom only, performs a post' do
        operation_request =
          stub_request(:post, "#{base_url}/#{path}")
            .with(headers: { 'CustomHeader' => 'CustomTest' })
            .to_return(status: 200, body: resource.to_json)

        group.fhir_operation(path, headers: { 'CustomHeader' => 'CustomTest' })

        expect(operation_request).to have_been_made.once
      end

      it 'as default only, performs a post' do
        operation_request =
          stub_request(:post, "#{base_url}/#{path}")
            .with(headers: { 'DefaultHeader' => 'ClientHeader' })
            .to_return(status: 200, body: resource.to_json)

        group.fhir_clients[:client_with_header] = client_with_header
        group.fhir_operation(path, client: :client_with_header)

        expect(operation_request).to have_been_made.once
      end

      it 'as both default and custom, performs a post' do
        operation_request =
          stub_request(:post, "#{base_url}/#{path}")
            .with(headers: { 'DefaultHeader' => 'ClientHeader', 'CustomHeader' => 'CustomTest' })
            .to_return(status: 200, body: resource.to_json)

        group.fhir_clients[:client_with_header] = client_with_header
        group.fhir_operation(path, client: :client_with_header, headers: { 'CustomHeader' => 'CustomTest' })

        expect(operation_request).to have_been_made.once
      end
    end

    context 'with oauth_credentials' do
      it 'performs a refresh if the token is about to expire' do
        client = group.fhir_client(:client_with_oauth_credentials)
        allow(client).to receive(:need_to_refresh?).and_return(true)
        allow(client).to receive(:able_to_refresh?).and_return(true)
        allow(group).to receive(:perform_refresh).with(client)

        group.fhir_operation(path, client: :client_with_oauth_credentials)

        expect(stub_operation_request).to have_been_made.once
        expect(group).to have_received(:perform_refresh)
      end
    end

    context 'with a base url that causes a TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:post)
          .and_raise(SocketError, 'Failed to open TCP')
      end

      it 'raises a test failure exception' do
        expect do
          group.fhir_operation 'abc'
        end.to raise_error(Inferno::Exceptions::AssertionException, 'Failed to open TCP')
      end
    end

    context 'with a base url that causes a non-TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:post)
          .and_raise(SocketError, 'not a TCP error')
      end

      it 'raises the error' do
        expect do
          group.fhir_operation 'abc'
        end.to raise_error(SocketError, 'not a TCP error')
      end
    end
  end

  describe '#fhir_get_capability_statement' do
    let(:resource) { FHIR::CapabilityStatement.new(fhirVersion: '4.0.1') }
    let(:stub_capability_request) do
      stub_request(:get, "#{base_url}/metadata")
        .to_return(status: 200, body: resource.to_json)
    end

    before do
      stub_capability_request
    end

    it 'performs a FHIR read' do
      group.fhir_get_capability_statement

      expect(stub_capability_request).to have_been_made.once
    end

    it 'returns an Inferno::Entities::Request' do
      result = group.fhir_get_capability_statement

      expect(result).to be_a(Inferno::Entities::Request)
    end

    it 'adds the request to the list of requests' do
      result = group.fhir_get_capability_statement

      expect(group.requests).to include(result)
      expect(group.request).to eq(result)
    end

    context 'with the client parameter' do
      it 'uses that client' do
        other_url = 'http://www.example.com/fhir/r4'
        group.fhir_clients[:other_client] = FHIR::Client.new(other_url)

        other_request_stub =
          stub_request(:get, "#{other_url}/metadata")
            .to_return(status: 200, body: resource.to_json)

        group.fhir_get_capability_statement(client: :other_client)

        expect(other_request_stub).to have_been_made
        expect(stub_capability_request).to_not have_been_made
      end
    end

    context 'with a base url that causes a TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:conformance_statement)
          .and_raise(SocketError, 'Failed to open TCP')
      end

      it 'raises a test failure exception' do
        expect do
          group.fhir_get_capability_statement
        end.to raise_error(Inferno::Exceptions::AssertionException, 'Failed to open TCP')
      end
    end

    context 'with a base url that causes a non-TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:conformance_statement)
          .and_raise(SocketError, 'not a TCP error')
      end

      it 'raises the error' do
        expect do
          group.fhir_get_capability_statement
        end.to raise_error(SocketError, 'not a TCP error')
      end
    end
  end

  describe '#fhir_read' do
    let(:stub_read_request) do
      stub_request(:get, "#{base_url}/#{resource.resourceType}/#{resource_id}")
        .to_return(status: 200, body: resource.to_json)
    end

    before do
      stub_read_request
    end

    it 'performs a FHIR read' do
      group.fhir_read(resource.resourceType, resource_id)

      expect(stub_read_request).to have_been_made.once
    end

    it 'returns an Inferno::Entities::Request' do
      result = group.fhir_read(resource.resourceType, resource_id)

      expect(result).to be_a(Inferno::Entities::Request)
    end

    it 'adds the request to the list of requests' do
      result = group.fhir_read(resource.resourceType, resource_id)

      expect(group.requests).to include(result)
      expect(group.request).to eq(result)
    end

    context 'with the client parameter' do
      it 'uses that client' do
        other_url = 'http://www.example.com/fhir/r4'
        group.fhir_clients[:other_client] = FHIR::Client.new(other_url)

        other_request_stub =
          stub_request(:get, "#{other_url}/#{resource.resourceType}/#{resource_id}")
            .to_return(status: 200, body: resource.to_json)

        group.fhir_read(resource.resourceType, resource_id, client: :other_client)

        expect(other_request_stub).to have_been_made
        expect(stub_read_request).to_not have_been_made
      end
    end

    context 'with oauth_credentials' do
      it 'performs a refresh if the token is about to expire' do
        client = group.fhir_client(:client_with_oauth_credentials)
        allow(client).to receive(:need_to_refresh?).and_return(true)
        allow(client).to receive(:able_to_refresh?).and_return(true)
        allow(group).to receive(:perform_refresh).with(client)

        group.fhir_read(resource.resourceType, resource_id, client: :client_with_oauth_credentials)

        expect(stub_read_request).to have_been_made.once
        expect(group).to have_received(:perform_refresh)
      end
    end

    context 'with a base url that causes a TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:read)
          .and_raise(SocketError, 'Failed to open TCP')
      end

      it 'raises a test failure exception' do
        expect do
          group.fhir_read :patient, '0'
        end.to raise_error(Inferno::Exceptions::AssertionException, 'Failed to open TCP')
      end
    end

    context 'with a base url that causes a non-TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:read)
          .and_raise(SocketError, 'not a TCP error')
      end

      it 'raises the error' do
        expect do
          group.fhir_read :patient, '0'
        end.to raise_error(SocketError, 'not a TCP error')
      end
    end
  end

  describe '#fhir_create' do
    let(:stub_create_request) do
      stub_request(:post, "#{base_url}/#{resource.resourceType}")
        .with(body: resource.to_json)
        .to_return(status: 201, headers: { 'Location' => "#{base_url}/#{resource.resourceType}/#{resource.id}" })
    end

    before do
      stub_create_request
    end

    it 'performs a FHIR create' do
      group.fhir_create(resource)

      expect(stub_create_request).to have_been_made.once
    end
  end

  describe '#fhir_transaction' do
    let(:stub_transaction_request) do
      stub_request(:post, "#{base_url}/")
        .with(body: resource.to_json)
        .to_return(status: 200)
    end
    let(:resource) do
      FHIR::Bundle.new(
        type: 'transaction',
        entry: [
          {
            resource: FHIR::Patient.new(id: '123'),
            request: {
              method: 'POST',
              url: 'Patient'
            }
          }
        ]
      )
    end

    before do
      stub_transaction_request
    end

    it 'performs a FHIR transaction' do
      group.fhir_transaction(resource)

      expect(stub_transaction_request).to have_been_made.once
    end

    it 'allows a transaction bundle to be built from scratch' do
      group.fhir_client.begin_transaction
      group.fhir_client.add_transaction_request('POST', nil, resource.entry.first.resource)
      group.fhir_transaction

      expect(stub_transaction_request).to have_been_made.once
    end
  end

  describe '#fhir_search' do
    let(:stub_get_search_request) do
      stub_request(:get, "#{base_url}/#{resource.resourceType}?patient=123")
        .to_return(status: 200, body: bundle.to_json)
    end
    let(:stub_post_search_request) do
      stub_request(:post, "#{base_url}/#{resource.resourceType}/_search")
        .with(body: search_params)
        .to_return(status: 200, body: bundle.to_json)
    end

    context 'when performing a GET search' do
      before do
        stub_get_search_request
      end

      it 'performs a FHIR search' do
        group.fhir_search(resource.resourceType, params: { patient: 123 })

        expect(stub_get_search_request).to have_been_made.once
      end

      it 'returns an Inferno::Entities::Request' do
        result = group.fhir_search(resource.resourceType, params: { patient: 123 })

        expect(result).to be_a(Inferno::Entities::Request)
      end

      it 'adds the request to the list of requests' do
        result = group.fhir_search(resource.resourceType, params: { patient: 123 })

        expect(group.requests).to include(result)
        expect(group.request).to eq(result)
      end

      context 'with the client parameter' do
        it 'uses that client' do
          other_url = 'http://www.example.com/fhir/r4'
          group.fhir_clients[:other_client] = FHIR::Client.new(other_url)

          other_request_stub =
            stub_request(:get, "#{other_url}/#{resource.resourceType}?patient=123")
              .to_return(status: 200, body: resource.to_json)

          group.fhir_search(resource.resourceType, client: :other_client, params: { patient: 123 })

          expect(other_request_stub).to have_been_made
          expect(stub_get_search_request).to_not have_been_made
        end
      end
    end

    context 'when performing a POST search' do
      let(:search_params) { { patient: '123' } }

      before do
        stub_post_search_request
      end

      it 'performs a FHIR search' do
        group.fhir_search(resource.resourceType, params: search_params, search_method: :post)

        expect(stub_post_search_request).to have_been_made.once
      end
    end

    context 'with oauth_credentials' do
      it 'performs a refresh if the token is about to expire' do
        stub_get_search_request
        client = group.fhir_client(:client_with_oauth_credentials)
        allow(client).to receive(:need_to_refresh?).and_return(true)
        allow(client).to receive(:able_to_refresh?).and_return(true)
        allow(group).to receive(:perform_refresh).with(client)

        group.fhir_search(resource.resourceType, params: { patient: 123 }, client: :client_with_oauth_credentials)

        expect(stub_get_search_request).to have_been_made.once
        expect(group).to have_received(:perform_refresh)
      end
    end

    context 'with a base url that causes a TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:search)
          .and_raise(SocketError, 'Failed to open TCP')
      end

      it 'raises a test failure exception' do
        expect do
          group.fhir_search :patient
        end.to raise_error(Inferno::Exceptions::AssertionException, 'Failed to open TCP')
      end
    end

    context 'with a base url that causes a non-TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:search)
          .and_raise(SocketError, 'not a TCP error')
      end

      it 'raises the error' do
        expect do
          group.fhir_search :patient
        end.to raise_error(SocketError, 'not a TCP error')
      end
    end
  end

  describe '#fhir_delete' do
    let(:stub_delete_request) do
      stub_request(:delete, "#{base_url}/#{resource.resourceType}/#{resource_id}")
        .to_return(status: 202)
    end

    before do
      stub_delete_request
    end

    it 'performs a FHIR delete' do
      group.fhir_delete(resource.resourceType, resource_id)

      expect(stub_delete_request).to have_been_made.once
    end

    it 'returns an Inferno::Entities::Request' do
      result = group.fhir_delete(resource.resourceType, resource_id)

      expect(result).to be_a(Inferno::Entities::Request)
    end

    it 'adds the request to the list of requests' do
      result = group.fhir_delete(resource.resourceType, resource_id)

      expect(group.requests).to include(result)
      expect(group.request).to eq(result)
    end

    context 'with the client parameter' do
      it 'uses that client' do
        other_url = 'http://www.example.com/fhir/r4'
        group.fhir_clients[:other_client] = FHIR::Client.new(other_url)

        other_request_stub =
          stub_request(:delete, "#{other_url}/#{resource.resourceType}/#{resource_id}")
            .to_return(status: 202)

        group.fhir_delete(resource.resourceType, resource_id, client: :other_client)

        expect(other_request_stub).to have_been_made
        expect(stub_delete_request).to_not have_been_made
      end
    end

    context 'with a base url that causes a TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:delete)
          .and_raise(SocketError, 'Failed to open TCP')
      end

      it 'raises a test failure exception' do
        expect do
          group.fhir_delete :patient, '0'
        end.to raise_error(Inferno::Exceptions::AssertionException, 'Failed to open TCP')
      end
    end

    context 'with a base url that causes a non-TCP error' do
      before do
        allow_any_instance_of(FHIR::Client)
          .to receive(:delete)
          .and_raise(SocketError, 'not a TCP error')
      end

      it 'raises the error' do
        expect do
          group.fhir_delete :patient, '0'
        end.to raise_error(SocketError, 'not a TCP error')
      end
    end
  end

  describe '#requests' do
    it 'returns an array of the requests made' do
      ids = [1, 2, 3]

      ids.each do |id|
        stub_request(:get, "#{base_url}/Patient/#{id}")
          .to_return(status: 200, body: FHIR::Patient.new(id:).to_json)

        group.fhir_read('Patient', id)

        expect(group.requests.length).to eq(id)
      end

      expect(group.requests).to all(be_a(Inferno::Entities::Request))
    end
  end

  describe '#request' do
    it 'returns the most recent FHIR request' do
      ids = [1, 2, 3]

      ids.each do |id|
        stub_request(:get, "#{base_url}/Patient/#{id}")
          .to_return(status: 200, body: FHIR::Patient.new(id:).to_json)
      end

      requests = ids.map { |id| group.fhir_read('Patient', id) }

      expect(group.request).to equal(requests.last)
      expect(group.request).to be_a(Inferno::Entities::Request)
    end
  end

  describe '#response' do
    it 'returns the response from the most recent request' do
      response = 'RESPONSE'

      allow(group).to receive(:request).and_return(OpenStruct.new(response:))

      expect(group.response).to eq(response)
    end
  end

  describe '#resource' do
    it 'returns the resource from the most recent request' do
      resource = 'RESOURCE'

      allow(group).to receive(:request).and_return(OpenStruct.new(resource:))

      expect(group.resource).to eq(resource)
    end
  end

  describe '#fhir_class_from_resource_type' do
    it 'returns a FHIR class from a snake case string' do
      expect(group.fhir_class_from_resource_type('care_plan')).to eq(FHIR::CarePlan)
    end

    it 'returns a FHIR class from a camel case string' do
      expect(group.fhir_class_from_resource_type('CarePlan')).to eq(FHIR::CarePlan)
    end

    it 'returns a FHIR class from a snake case symbol' do
      expect(group.fhir_class_from_resource_type(:care_plan)).to eq(FHIR::CarePlan)
    end

    it 'returns a FHIR class from a camel case symbol' do
      expect(group.fhir_class_from_resource_type(:CarePlan)).to eq(FHIR::CarePlan)
    end

    it 'returns a FHIR class from a FHIR class' do
      expect(group.fhir_class_from_resource_type(FHIR::CarePlan)).to eq(FHIR::CarePlan)
    end
  end

  describe '#bearer_token' do
    let(:client) { group.fhir_client(:client_with_bearer_token) }

    it 'uses the given bearer token in the security header' do
      expect(client.security_headers).to eq({ 'Authorization' => 'Bearer some_token' })
    end

    it 'has the auth flags set correctly' do
      expect(client.use_basic_auth).to be_truthy
      expect(client.use_oauth2_auth).to be_falsey
    end
  end

  describe '#oauth_credentials' do
    let(:client) { group.fhir_client(:client_with_oauth_credentials) }

    it 'uses the given bearer token in the security header' do
      expect(client.security_headers).to eq({ 'Authorization' => 'Bearer ACCESS_TOKEN' })
    end

    it 'has the auth flags set correctly' do
      expect(client.use_basic_auth).to be_truthy
      expect(client.use_oauth2_auth).to be_falsey
    end

    it 'stores the credentials on the client' do
      expect(client.instance_variable_get(:@oauth_credentials)).to be_a(Inferno::DSL::OAuthCredentials)
    end
  end

  describe '#perform_refresh' do
    let(:client) { group.fhir_client(:client_with_oauth_credentials) }
    let(:credentials) { client.oauth_credentials }
    let(:token_url) { client.token_url }

    context 'when the refresh is unsuccessful' do
      it 'does not update credentials' do
        original_credentials = credentials.to_hash
        token_request =
          stub_request(:post, credentials.token_url)
            .to_return(status: 400)

        group.perform_refresh(client)

        expect(client.oauth_credentials.to_hash).to eq(original_credentials)
        expect(token_request).to have_been_made
      end
    end

    context 'when the refresh is successful' do
      let(:token_response_body) do
        {
          access_token: 'NEW_ACCESS_TOKEN',
          token_type: 'bearer',
          expires_in: 5000,
          scope: 'NEW_SCOPES',
          refresh_token: 'NEW_REFRESH_TOKEN'
        }
      end

      it 'updates the credentials on the client' do
        token_request =
          stub_request(:post, credentials.token_url)
            .to_return(status: 200, body: JSON.generate(token_response_body))

        group.perform_refresh(client)

        expect(token_request).to have_been_made
        expect(credentials.access_token).to eq(token_response_body[:access_token])
        expect(credentials.refresh_token).to eq(token_response_body[:refresh_token])
      end

      it 'updates the credentials in the database' do
        session = repo_create(:test_session, test_suite_id: 'demo')
        allow(group).to receive(:test_session_id).and_return(session.id)

        credentials.name = 'name'
        token_request =
          stub_request(:post, credentials.token_url)
            .to_return(status: 200, body: JSON.generate(token_response_body))

        group.perform_refresh(client)

        expect(token_request).to have_been_made

        persisted_credentials =
          session_data_repo.load(test_session_id: group.test_session_id, name: 'name', type: 'oauth_credentials')

        expect(persisted_credentials.to_hash).to eq(credentials.to_hash)
      end
    end
  end
end
