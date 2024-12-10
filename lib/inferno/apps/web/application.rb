require 'hanami/middleware/body_parser'
require_relative 'router'

# Only required to monkey patch the JSON parser to support application/fhir+json
require 'hanami/middleware/body_parser/json_parser'
require_relative '../../ext/json_parser'

module Inferno
  module Web
    def self.app
      Rack::Builder.new do
        use Hanami::Middleware::BodyParser, :json
        run Inferno::Web::Router
      end
    end
  end
end
