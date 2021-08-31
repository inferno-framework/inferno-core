class FHIRClientDSLTestClass
  include Inferno::DSL::FHIRClient
  extend Inferno::DSL::Configurable

  def test_session_id
    nil
  end

  fhir_client :client_with_bearer_token do
    url 'http://www.example.com/fhir'
    bearer_token 'some_token'
  end
end

RSpec.describe Inferno::DSL::FHIRClient do
  let(:group) { FHIRClientDSLTestClass.new }
  let(:base_url) { 'http://www.example.com/fhir' }
  let(:resource_id) { '123' }
  let(:resource) { FHIR::CarePlan.new(id: resource_id) }
  let(:default_client) { FHIR::Client.new(base_url) }
  let(:bundle) { FHIR::Bundle.new(entry: [{ resource: resource }]) }

  def setup_default_client
    group.instance_variable_set(
      :@fhir_clients,
      { default: default_client }
    )
  end

  describe '#fhir_client' do
    before { setup_default_client }

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
  end

  describe '#fhir_operation' do
    let(:path) { 'abc' }
    let(:stub_operation_request) do
      stub_request(:post, "#{base_url}/#{path}")
        .to_return(status: 200, body: resource.to_json)
    end

    before do
      setup_default_client
      stub_operation_request
    end

    it 'performs a get' do
      group.fhir_operation(path)

      expect(stub_operation_request).to have_been_made.once
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

      it 'as custom only, performs a get' do
        group.fhir_operation(path, headers: { 'CustomHeader' => 'CustomTest' })

        expect(stub_custom_header_request).to have_been_made.once
      end

      it 'as default only, performs a get' do
        group.fhir_clients[:client_with_header] = client_with_header
        group.fhir_operation(path, client: :client_with_header)

        expect(stub_default_header_request).to have_been_made.once
      end

      it 'as both default and custom, performs a get' do
        group.fhir_clients[:client_with_header] = client_with_header
        group.fhir_operation(path, client: :client_with_header, headers: { 'CustomHeader' => 'CustomTest' })

        expect(stub_custom_and_default_header_request).to have_been_made.once
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
      setup_default_client
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
  end

  describe '#fhir_read' do
    let(:stub_read_request) do
      stub_request(:get, "#{base_url}/#{resource.resourceType}/#{resource_id}")
        .to_return(status: 200, body: resource.to_json)
    end

    before do
      setup_default_client
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
  end

  describe '#fhir_search' do
    let(:stub_search_request) do
      stub_request(:get, "#{base_url}/#{resource.resourceType}?patient=123")
        .to_return(status: 200, body: bundle.to_json)
    end

    before do
      setup_default_client
      stub_search_request
    end

    it 'performs a FHIR search' do
      group.fhir_search(resource.resourceType, params: { patient: 123 })

      expect(stub_search_request).to have_been_made.once
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
        expect(stub_search_request).to_not have_been_made
      end
    end
  end

  describe '#requests' do
    it 'returns an array of the requests made' do
      setup_default_client
      ids = [1, 2, 3]

      ids.each do |id|
        stub_request(:get, "#{base_url}/Patient/#{id}")
          .to_return(status: 200, body: FHIR::Patient.new(id: id).to_json)

        group.fhir_read('Patient', id)

        expect(group.requests.length).to eq(id)
      end

      expect(group.requests).to all(be_a(Inferno::Entities::Request))
    end
  end

  describe '#request' do
    it 'returns the most recent FHIR request' do
      setup_default_client
      ids = [1, 2, 3]

      ids.each do |id|
        stub_request(:get, "#{base_url}/Patient/#{id}")
          .to_return(status: 200, body: FHIR::Patient.new(id: id).to_json)
      end

      requests = ids.map { |id| group.fhir_read('Patient', id) }

      expect(group.request).to equal(requests.last)
      expect(group.request).to be_a(Inferno::Entities::Request)
    end
  end

  describe '#response' do
    it 'returns the response from the most recent request' do
      response = 'RESPONSE'

      allow(group).to receive(:request).and_return(OpenStruct.new(response: response))

      expect(group.response).to eq(response)
    end
  end

  describe '#resource' do
    it 'returns the resource from the most recent request' do
      resource = 'RESOURCE'

      allow(group).to receive(:request).and_return(OpenStruct.new(resource: resource))

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

  describe '#fhir_client_with_bearer_token' do
    let(:client) { group.fhir_client(:client_with_bearer_token) }

    it 'uses the given bearer token in the security header' do
      expect(client.security_headers).to eq({ 'Authorization' => 'Bearer some_token' })
    end

    it 'has the auth flags set correctly' do
      expect(client.use_basic_auth).to be_truthy
      expect(client.use_oauth2_auth).to be_falsey
    end
  end
end
