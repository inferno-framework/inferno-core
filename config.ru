require_relative 'lib/inferno/config/application'

base_path = ENV.fetch('BASE_PATH', '')
public_path = "/#{base_path}/public".gsub('//', '/')

static_files =
  Dir.glob(File.join('lib', 'inferno', 'public', '*'))
    .each_with_object({}) { |filename, hash| hash["#{public_path}/#{File.basename(filename)}"] = "/public/#{File.basename(filename)}" }

puts static_files.inspect
use Rack::Static, urls: static_files, root: 'lib/inferno'

Inferno::Application.finalize!

use Inferno::Utils::Middleware::RequestLogger

run Inferno::Web.app
