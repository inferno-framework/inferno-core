require 'spec_helper'
require 'rack/test'
require_relative '../lib/inferno/apps/web/application'

module RequestHelpers
  def app
    Inferno::Web.app
  end

  def post_json(path, data)
    post path, data.to_json, 'CONTENT_TYPE' => 'application/json'
  end

  def post_form_data(path, data)
    post path, data, 'CONTENT_TYPE' => 'multipart/form-data'
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
