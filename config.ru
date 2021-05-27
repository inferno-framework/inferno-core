require_relative 'lib/inferno'

use Rack::Static, urls: ['/public'], root: 'lib/inferno/public'

Inferno::Application.finalize!

use Inferno::Utils::Middleware::RequestLogger

run Inferno::Web.app
