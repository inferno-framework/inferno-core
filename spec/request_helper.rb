require 'spec_helper'
require 'rack/test'
require_relative '../lib/inferno/apps/web/application'
require_relative '../lib/inferno/utils/middleware/request_logger'

module RequestHelpers
  def app
    Rack::Builder.new do
      use Inferno::Utils::Middleware::RequestLogger
      run Inferno::Web.app
    end
  end

  def post_json(path, data)
    post path, data.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  def parsed_body
    JSON.parse(last_response.body)
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/requests/}) do |metadata|
    metadata[:request] = true
  end

  config.include Rack::Test::Methods, request: true
  config.include RequestHelpers, request: true
end
