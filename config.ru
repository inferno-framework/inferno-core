require_relative 'lib/inferno'

use Rack::Static, urls: ['/public'], root: 'lib/inferno'

Inferno::Application.finalize!

use Inferno::Utils::Middleware::RequestLogger

run Inferno::Web.app
