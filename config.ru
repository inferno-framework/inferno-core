require_relative 'lib/inferno'
require_relative 'lib/inferno/utils/middleware/request_logger'

use Rack::Static,
    urls: Inferno::Utils::StaticAssets.static_assets_map,
    root: Inferno::Utils::StaticAssets.inferno_path

Inferno::Application.finalize!

use Inferno::Utils::Middleware::RequestLogger

require_relative 'lib/inferno/apps/web/application'

run Inferno::Web.app
