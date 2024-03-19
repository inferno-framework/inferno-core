require_relative 'lib/inferno'

use Rack::Static,
    urls: Inferno::Utils::StaticAssets.static_assets_map,
    root: Inferno::Utils::StaticAssets.inferno_path

Inferno::Application.finalize!

use Inferno::Utils::Middleware::RequestLogger
use Inferno::Utils::Middleware::RequestRecorder

run Inferno::Web.app
