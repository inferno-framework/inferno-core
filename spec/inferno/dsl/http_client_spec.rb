class HTTPClientDSLTestClass
  include Inferno::DSL::HTTPClient
  extend Inferno::DSL::Configurable

  def test_session_id
    nil
  end
end

RSpec.describe Inferno::DSL::HTTPClient do
  let(:group) { HTTPClientDSLTestClass.new }
  let(:base_url) { 'http://www.example.com' }
  let(:other_url) { 'http://www.example.com/2' }
  let(:resource_id) { '123' }
  let(:resource) { FHIR::CarePlan.new(id: resource_id) }
  let(:response_body) { 'RESPONSE_BODY' }
  let(:default_client) do
    block = proc { url 'http://www.example.com' }
    Inferno::DSL::HTTPClientBuilder.new.build(group, block)
  end
  let(:other_client) do
    block = proc { url 'http://www.example.com/2' }
    Inferno::DSL::HTTPClientBuilder.new.build(group, block)
  end
  let(:client_with_header) do
    block =
      proc do
        url 'http://www.example.com'
        headers 'ClientHeader' => 'DefaultHeader'
      end
    Inferno::DSL::HTTPClientBuilder.new.build(group, block)
  end

  def setup_default_client
    group.instance_variable_set(
      :@http_clients,
      { default: default_client }
    )
  end

  describe '#http_client' do
    before { setup_default_client }

    context 'without an argument' do
      it 'returns the default HTTP client' do
        expect(group.http_client).to eq(default_client)
      end

      it 'raises an error if no default HTTP client has been created'
    end

    context 'with an argument' do
      it 'returns the specified HTTP client' do
        name = :other_client
        group.http_clients[name] = other_client

        expect(group.http_client(name)).to eq(other_client)
      end

      it 'raises an error if the HTTP client is not known'
    end
  end

  describe '#get' do
    context 'with a default client defined' do
      before do
        setup_default_client
      end

      context 'without a url argument' do
        let(:stub_get_request) do
          stub_request(:get, base_url)
            .to_return(status: 200, body: response_body)
        end

        before { stub_get_request }

        it "performs a HTTP GET to the default client's base url" do
          group.get

          expect(stub_get_request).to have_been_made.once
        end

        it 'returns an Inferno::Entities::Request' do
          result = group.get

          expect(result).to be_a(Inferno::Entities::Request)
        end

        it 'adds the request to the list of requests' do
          result = group.get

          expect(group.requests).to include(result)
          expect(group.request).to eq(result)
        end
      end

      context 'with a url argument' do
        it 'performs a GET to the base_url + path' do
          path = 'abc'
          stubbed_request =
            stub_request(:get, "#{base_url}/#{path}")
              .to_return(status: 200, body: response_body, headers: {})

          group.get(path)

          expect(stubbed_request).to have_been_made.once
        end
      end

      context 'with custom headers' do
        it "performs a HTTP GET to the default client's base url" do
          stub_get_header_request =
            stub_request(:get, base_url)
              .with(headers: { 'Warning' => 'Placeholder warning' })
              .to_return(status: 200, body: '', headers: {})

          group.get(headers: { 'Warning' => 'Placeholder warning' })
          expect(stub_get_header_request).to have_been_made.once
        end

        it "perfoms a HTTP GET that includes the default client's existing headers" do
          stub_get_header_request =
            stub_request(:get, base_url)
              .with(headers: { 'Clientheader' => 'DefaultHeader', 'Customheader' => 'MergedCustom' })
              .to_return(status: 200, body: '', headers: {})

          group.http_clients[:client_with_header] = client_with_header
          group.get(client: :client_with_header, headers: { 'CustomHeader' => 'MergedCustom' })

          expect(stub_get_header_request).to have_been_made.once
        end
      end

      context 'with the client parameter' do
        it 'uses that client' do
          stub_get_request =
            stub_request(:get, other_url)
              .to_return(status: 200, body: '', headers: {})
          group.http_clients[:other_client] = other_client

          group.get(client: :other_client)

          expect(stub_get_request).to have_been_made.once
        end

        it 'uses that client and its headers' do
          stub_get_header_request =
            stub_request(:get, base_url)
              .with(headers: { 'ClientHeader' => 'DefaultHeader' })
              .to_return(status: 200, body: '', headers: {})

          group.http_clients[:client_with_header] = client_with_header
          group.get(client: :client_with_header)

          expect(stub_get_header_request).to have_been_made.once
        end
      end
    end

    context 'without a default client defined' do
      it 'makes a request to an absolute url' do
        url = 'https://example.com/abc'
        stubbed_request =
          stub_request(:get, url)
            .to_return(status: 200, body: response_body)

        group.get(url)

        expect(stubbed_request).to have_been_made.once
      end

      it 'raises an error if given a relative url' do
        url = 'abc'

        expect { group.get(url) }.to raise_error(/absolute url/)
      end

      it 'makes a request to an asbolute url with custom headers' do
        url = 'https://example.com/abc'
        stub_get_header_request =
          stub_request(:get, url)
            .with(headers: { 'Warning' => 'Placeholder warning' })
            .to_return(status: 200, body: '', headers: {})

        group.get(url, headers: { 'Warning' => 'Placeholder warning' })
        expect(stub_get_header_request).to have_been_made.once
      end
    end
  end

  describe '#post' do
    let(:request_body) { 'REQUEST_BODY' }

    context 'with a default client defined' do
      before do
        setup_default_client
      end

      context 'without a url argument' do
        it "performs a HTTP POST to the default client's base url" do
          stubbed_request =
            stub_request(:post, base_url)
              .to_return(status: 200, body: response_body)

          group.post

          expect(stubbed_request).to have_been_made.once
        end

        it 'sends the provided body' do
          stubbed_request =
            stub_request(:post, base_url)
              .with(body: request_body)
              .to_return(status: 200, body: response_body)

          group.post(body: request_body)

          expect(stubbed_request).to have_been_made.once
        end

        it 'returns an Inferno::Entities::Request' do
          stub_request(:post, base_url)
            .to_return(status: 200, body: response_body)

          result = group.post

          expect(result).to be_a(Inferno::Entities::Request)
        end

        it 'adds the request to the list of requests' do
          stub_request(:post, base_url)
            .to_return(status: 200, body: response_body)

          result = group.post

          expect(group.requests).to include(result)
          expect(group.request).to eq(result)
        end
      end

      context 'with a url argument' do
        it 'performs a POST to the base_url + url' do
          path = 'abc'
          stubbed_request =
            stub_request(:post, "#{base_url}/#{path}")
              .to_return(status: 200, body: response_body)

          group.post(path)

          expect(stubbed_request).to have_been_made.once
        end
      end

      context 'with custom headers' do
        it "performs a HTTP POST to the default client's base url" do
          stub_get_header_request =
            stub_request(:post, base_url)
              .with(headers: { 'Warning' => 'Placeholder warning' })
              .to_return(status: 200, body: '', headers: {})

          group.post(headers: { 'Warning' => 'Placeholder warning' })
          expect(stub_get_header_request).to have_been_made.once
        end

        it "perfoms a HTTP POST that includes the default client's existing headers" do
          stub_get_header_request =
            stub_request(:post, base_url)
              .with(headers: { 'ClientHeader' => 'DefaultHeader', 'CustomHeader' => 'MergedCustom' })
              .to_return(status: 200, body: '', headers: {})

          group.http_clients[:client_with_header] = client_with_header
          group.post(client: :client_with_header, headers: { 'CustomHeader' => 'MergedCustom' })

          expect(stub_get_header_request).to have_been_made.once
        end
      end

      context 'with the client parameter' do
        it 'uses that client' do
          stubbed_request =
            stub_request(:post, other_url)
              .to_return(status: 200, body: response_body)

          group.http_clients[:other_client] = other_client

          group.post(client: :other_client)

          expect(stubbed_request).to have_been_made.once
        end

        it 'uses that client and its headers' do
          stub_get_header_request =
            stub_request(:post, base_url)
              .with(headers: { 'ClientHeader' => 'DefaultHeader' })
              .to_return(status: 200, body: '', headers: {})

          group.http_clients[:client_with_header] = client_with_header
          group.post(client: :client_with_header)

          expect(stub_get_header_request).to have_been_made.once
        end
      end
    end

    context 'without a default client defined' do
      it 'makes a request to an absolute url' do
        url = 'https://example.com/abc'
        stubbed_request =
          stub_request(:post, url)
            .to_return(status: 200, body: response_body)

        group.post(url)

        expect(stubbed_request).to have_been_made.once
      end

      it 'raises an error if given a relative url' do
        url = 'abc'

        expect { group.post(url) }.to raise_error(/absolute url/)
      end
    end
  end

  describe '#delete' do
    context 'with a default client defined' do
      before do
        setup_default_client
      end

      context 'without a url argument' do
        let(:stub_delete_request) do
          stub_request(:delete, base_url)
            .to_return(status: 202)
        end

        before { stub_delete_request }

        it "performs a HTTP DELETE to the default client's base url" do 
          group.delete

          expect(stub_delete_request).to have_been_made.once
        end 

        it 'returns an Inferno::Entities::Request' do
          result = group.delete

          expect(result).to be_a(Inferno::Entities::Request)
        end 

        it 'adds the request to the list of requests' do
          result = group.delete

          expect(group.requests).to include(result)
          expect(group.request).to eq(result)
        end
      end

      context 'with a url argument' do
        it 'performs a DELETE to the base_url + path' do 
          path = 'abc'
          stubbed_request =
            stub_request(:delete, "#{base_url}/#{path}")
              .to_return(status: 202)

          group.delete(path)

          expect(stubbed_request).to have_been_made.once
        end 
      end

      context 'with custom headers' do
        it "performs a HTTP Delete to the default client's base url using existing headers" do
          stub_delete_header_request =
            stub_request(:delete, base_url)
              .with(headers: { 'Warning' => 'Placeholder warning' })
              .to_return(status: 202)

          group.delete(headers: { 'Warning' => 'Placeholder warning' })
          expect(stub_delete_header_request).to have_been_made.once
        end

        it "performs a HTTP DELETE to the default client's base url using both default and custom headers" do
          stub_delete_header_request =
            stub_request(:delete, base_url)
              .with(headers: { 'Clientheader' => 'DefaultHeader', 'Customheader' => 'MergedCustom' })
              .to_return(status: 202)

          group.http_clients[:client_with_header] = client_with_header
          group.delete(client: :client_with_header, headers: { 'CustomHeader' => 'MergedCustom' })

          expect(stub_delete_header_request).to have_been_made.once
        end 
      end

      context 'with the client parameter' do
        it 'uses that client' do
          stub_delete_request =
            stub_request(:delete, other_url)
              .to_return(status: 202)
          group.http_clients[:other_client] = other_client

          group.delete(client: :other_client)

          expect(stub_delete_request).to have_been_made.once
        end

        it 'uses that client and its headers' do
          stub_delete_header_request =
            stub_request(:delete, base_url)
              .with(headers: { 'ClientHeader' => 'DefaultHeader' })
              .to_return(status: 202)

          group.http_clients[:client_with_header] = client_with_header
          group.delete(client: :client_with_header)

          expect(stub_delete_header_request).to have_been_made.once
        end
      end
    end

    context 'without a default client defined' do
      it 'makes a request to an absolute url' do
        url = 'https://example.com/abc'
        stubbed_request =
          stub_request(:delete, url)
            .to_return(status: 200)

        group.delete(url)

        expect(stubbed_request).to have_been_made.once
      end

      it 'raises an error if given a relative url' do
        url = 'abc'

        expect { group.delete(url) }.to raise_error(/absolute url/)
      end

      it 'makes a request to an absolute url with custom headers' do 
        url = 'https://example.com/abc'
        stub_delete_header_request =
          stub_request(:delete, url)
            .with(headers: { 'Warning' => 'Placeholder warning' })
            .to_return(status: 200)

        group.delete(url, headers: { 'Warning' => 'Placeholder warning' })
        expect(stub_delete_header_request).to have_been_made.once
      end 
    end
  end

  describe '#stream' do
    let(:generic_block) { Proc.new { |chunk| } }
    let(:streamed) { [] }
    let(:block) { proc { |chunk|  
      streamed << chunk
    } }
    context 'with a default client defined' do
      before do 
        setup_default_client
      end 

      context 'without a url argument' do 
        let(:stub_get_request) do
          stub_request(:get, base_url)
            .to_return(status: 200, body: response_body)
        end 

        before { stub_get_request }

        it "performs a HTTP GET to the default client's base url" do
          group.stream(generic_block)

          expect(stub_get_request).to have_been_made.once
        end

        it 'receives and stores a chunk of the response via :block' do
          group.stream(block) 

          expect(streamed).to eq([response_body])
        end 

        it 'returns an Inferno::Entities::Request' do
          result = group.stream(generic_block)

          expect(result).to be_a(Inferno::Entities::Request)
        end

        it 'adds the request to the list of requests' do
          result = group.stream(generic_block)

          expect(group.requests).to include(result)
          expect(group.request).to eq(result)
        end
      end 

      context 'with a url argument' do
        it 'performs a GET to the base_url + path' do
          path = 'abc'
          stubbed_request =
            stub_request(:get, "#{base_url}/#{path}")
              .to_return(status: 200, body: response_body, headers: {})

          group.stream(path, generic_block)

          expect(stubbed_request).to have_been_made.once
        end
      end

      context 'with custom headers' do
        it "performs a HTTP GET to the default client's base url" do
          stub_get_header_request =
            stub_request(:get, base_url)
              .with(headers: { 'Warning' => 'Placeholder warning' })
              .to_return(status: 200, body: '', headers: {})

          group.stream(generic_block, headers: { 'Warning' => 'Placeholder warning' })
          expect(stub_get_header_request).to have_been_made.once
        end

        it "perfoms a HTTP GET that includes the default client's existing headers" do
          stub_get_header_request =
            stub_request(:get, base_url)
              .with(headers: { 'Clientheader' => 'DefaultHeader', 'Customheader' => 'MergedCustom' })
              .to_return(status: 200, body: '', headers: {})

          group.http_clients[:client_with_header] = client_with_header
          group.stream(generic_block, client: :client_with_header, headers: { 'CustomHeader' => 'MergedCustom' })

          expect(stub_get_header_request).to have_been_made.once
        end
      end

      context 'with the client parameter' do
        it 'uses that client' do
          stub_get_request =
            stub_request(:get, other_url)
              .to_return(status: 200, body: '', headers: {})
          group.http_clients[:other_client] = other_client

          group.stream(generic_block, client: :other_client)

          expect(stub_get_request).to have_been_made.once
        end

        it 'uses that client and its headers' do
          stub_get_header_request =
            stub_request(:get, base_url)
              .with(headers: { 'ClientHeader' => 'DefaultHeader' })
              .to_return(status: 200, body: '', headers: {})

          group.http_clients[:client_with_header] = client_with_header
          group.stream(generic_block, client: :client_with_header)

          expect(stub_get_header_request).to have_been_made.once
        end
      end
    end

    context 'without a default client defined' do
      it 'makes a request to an absolute url' do
        url = 'https://example.com/abc'
        stubbed_request =
          stub_request(:get, url)
            .to_return(status: 200, body: response_body)

        group.stream(url, generic_block)

        expect(stubbed_request).to have_been_made.once
      end

      it 'receives and stores a chunk of the response via :block' do
        url = 'https://example.com/abc'
        stubbed_request =
          stub_request(:get, url)
            .to_return(status: 200, body: response_body)

        group.stream(url, block) 

        expect(streamed).to eq([response_body])
      end 

      it 'raises an error if given a relative url' do
        url = 'abc'

        expect { group.stream(url, generic_block) }.to raise_error(/absolute url/)
      end

      it 'makes a request to an asbolute url with custom headers' do
        url = 'https://example.com/abc'
        stub_get_header_request =
          stub_request(:get, url)
            .with(headers: { 'Warning' => 'Placeholder warning' })
            .to_return(status: 200, body: '', headers: {})

        group.stream(url, generic_block, headers: { 'Warning' => 'Placeholder warning' })
        expect(stub_get_header_request).to have_been_made.once
      end
    end
  end 

  describe '#requests' do
    it 'returns an array of the requests made' do
      stub_request(:get, base_url)
        .to_return(status: 200, body: response_body, headers: {})

      setup_default_client

      requests = (1..3).map do |i|
        group.get.tap { expect(group.requests.length).to eq(i) }
      end

      expect(group.requests).to eq(requests)
      expect(group.requests).to all(be_a(Inferno::Entities::Request))
    end
  end
end
