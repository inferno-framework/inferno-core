require_relative 'lib/inferno/config/application'

# TODO: encapsulate this somewhere
base_path = ENV.fetch('BASE_PATH', '')
public_path = "/#{base_path}/public".gsub('//', '/')

static_files =
  Dir.glob(File.join('lib', 'inferno', 'public', '*'))
    .each_with_object({}) do |filename, hash|
      hash["#{public_path}/#{File.basename(filename)}"] = "/public/#{File.basename(filename)}"
    end

use Rack::Static, urls: static_files, root: 'lib/inferno'

Inferno::Application.finalize!

use Inferno::Utils::Middleware::RequestLogger

run Inferno::Web.app
