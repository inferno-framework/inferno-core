require 'hanami/middleware/body_parser'
require_relative 'router'

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
