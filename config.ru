require_relative 'config/application'

use Rack::Static, urls: ['/public']

Inferno::Application.finalize!

use Inferno::Utils::Middleware::RequestLogger

run Inferno::Web.app
