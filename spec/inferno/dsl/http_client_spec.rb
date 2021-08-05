class HTTPClientDSLTestClass
  include Inferno::DSL::HTTPClient

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
    let(:stub_get_request) do
      stub_request(:get, "#{base_url}/?User-Agent=Faraday%20v1.2.0").
         with(headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Faraday v1.2.0'})
         .to_return(status: 200, body: response_body, headers: {})
    end
    let(:stub_get_header_request) do
      stub_request(:get, "http://www.example.com/?User-Agent=Faraday%20v1.2.0&Warning=Placeholder%20warning").
         with(
           headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Faraday v1.2.0',
          'Warning'=>'Placeholder warning'
           }).
         to_return(status: 200, body: "", headers: {})
    end

    before { stub_get_request }
    before { stub_get_header_request } 

    context 'with a default client defined' do
      before do
        setup_default_client
      end

      context 'without a url argument' do
        it "performs a HTTP GET to the default client's base url without additional header" do
          group.get

          expect(stub_get_request).to have_been_made.once
        end

        it "performs a HTTP GET to the default client's base url with an additional header" do

          result = group.get(headers: {'Warning' => 'Placeholder warning'})
          expect(stub_get_header_request).to have_been_made.once
        end

        it 'returns an Inferno::Entities::Request without additional header' do
          result = group.get

          expect(result).to be_a(Inferno::Entities::Request)
        end

        it 'returns an Inferno::Entities::Request with additional header' do
          result = group.get(headers: {'Warning' => 'Placeholder warning'})

          expect(result).to be_a(Inferno::Entities::Request)
        end

        it 'adds the request without additional header to the list of requests' do
          result = group.get

          expect(group.requests).to include(result)
          expect(group.request).to eq(result)
        end

        it 'adds the request with additional header to the list of requests' do
          result = group.get(headers: {'Warning' => 'Placeholder warning'})

          expect(group.requests).to include(result)
          expect(group.request).to eq(result)
        end
      end

      context 'with a url argument' do
        it 'performs a GET to the base_url + url' do
          path = 'abc'
          stubbed_request =
            stub_request(:get, "#{base_url}/#{path}?User-Agent=Faraday%20v1.2.0").
              with(headers: {
                'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'=>'Faraday v1.2.0'})
              .to_return(status: 200, body: response_body, headers: {})

          group.get(path)

          expect(stubbed_request).to have_been_made.once
        end
      end

      context 'with the client parameter' do
        let(:stub_get_request) do
          stub_request(:get, "#{other_url}?User-Agent=Faraday%20v1.2.0").
            with(headers: {
              'Accept'=>'*/*',
              'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'User-Agent'=>'Faraday v1.2.0'})
            .to_return(status: 200, body: "", headers: {})
        end

        it 'uses that client' do
          group.http_clients[:other_client] = other_client

          group.get(client: :other_client)

          expect(stub_get_request).to have_been_made.once
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

      context 'with the client parameter' do
        it 'uses that client' do
          stubbed_request =
            stub_request(:post, other_url)
              .to_return(status: 200, body: response_body)

          group.http_clients[:other_client] = other_client

          group.post(client: :other_client)

          expect(stubbed_request).to have_been_made.once
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

  describe '#requests' do
    it 'returns an array of the requests made' do
      stub_request(:get, "#{base_url}/?User-Agent=Faraday%20v1.2.0").
         with(headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent'=>'Faraday v1.2.0'})
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
