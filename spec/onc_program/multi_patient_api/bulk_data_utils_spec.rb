require_relative '../../../dev_suites/dev_multi_patient_api/bulk_data_access/bulk_data_utils'

class BulkDataUtilsTestClass
  include Inferno::DSL::HTTPClient
  extend Inferno::DSL::Configurable

  include BulkDataUtils

  def test_session_id 
    nil 
  end 
end 

RSpec.describe BulkDataUtils do
  let(:group) { BulkDataUtilsTestClass.new }
  let(:url) { 'https://example1.com' }
  let(:basic_body) { 'single line response_body' }
  let(:multi_line_body) { "multi\nline\nresponse\nbody\n" }
  let(:generic_block) { Proc.new { |chunk| } }
  let(:streamed_chunks) { [] }
  let(:streamed_response) { [] }
  let(:process_line_block) { Proc.new { |chunk| streamed_chunks << chunk + ' touched' } }
  let(:process_response_block) { Proc.new { |response| streamed_response << response[:headers][0].value }}
  let(:client) do
    block = proc { url url }
    Inferno::DSL::HTTPClientBuilder.new.build(group, block)
  end

  describe 'stream_ndjson' do

    it 'makes a stream request using the given endpoint' do 
      stub_request(:get, "#{url}")
        .to_return(status: 200, body: "", headers: {})

      group.stream_ndjson(url, {}, generic_block, generic_block)

      expect(group.response[:status]).to eq(200)
    end 

    it 'applies process_header once, upon reception of a single, one-line chunk' do
      stub_request(:get, "#{url}")
        .to_return(status: 200, body: basic_body, headers: {'Application' => 'expected'})

      group.stream_ndjson(url, {}, generic_block, process_response_block)

      expect(streamed_response).to eq(['expected'])
    end

    it 'applies process_header serveral times, upon reception of multiple chunks' do

    end

    it 'applies process_chunk_line to single, one-line chunk of a stream' do
      stub_request(:get, "#{url}")
        .to_return(status: 200, body: basic_body, headers: {})

      group.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq([basic_body + ' touched'])
    end

    it 'applies process_chunk_line to single, multi-line chunk of a stream' do
      stub_request(:get, "#{url}")
        .to_return(status: 200, body: multi_line_body, headers: {})

      group.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq(["multi\n touched", "line\n touched", "response\n touched", "body\n touched"])
    end 
    
    # TODO: Unsure how to mimic streamed_chunks data files
    it 'applies process_chunk_line to multiple, one-line chunks of a stream' do
      
    end 

    it 'applies process_chunk_line to multiple, multi-line chunks of a stream' do
      
    end 
  end 
end 