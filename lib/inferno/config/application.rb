require 'active_support/all'
require 'dotenv'
require 'dry/system'
require 'sequel'
require_relative 'boot'

module Inferno
  class Application < Dry::System::Container
    ::Inferno::Import = injector

    use :env, inferrer: -> { ENV.fetch('APP_ENV', :development).to_sym }

    raw_js_host = ENV.fetch('JS_HOST', '')
    base_path = ENV.fetch('BASE_PATH', '')
    public_path = base_path.blank? ? '/public' : "/#{base_path}/public"
    jwks_path = base_path.blank? ? '/jwks.json' : "/#{base_path}/jwks.json"
    js_host = raw_js_host.present? ? "#{raw_js_host}/public" : public_path

    Application.register('js_host', js_host)
    Application.register('base_path', base_path)
    Application.register('public_path', public_path)
    Application.register('async_jobs', ENV['ASYNC_JOBS'] != 'false')
    Application.register('inferno_host', ENV.fetch('INFERNO_HOST', 'http://localhost:4567'))
    Application.register('base_url', URI.join(Application['inferno_host'], base_path).to_s)
    Application.register('jwks_url', URI.join(Application['inferno_host'], jwks_path).to_s)
    Application.register('cache_bust_token', SecureRandom.uuid)

    configure do |config|
      config.root = File.expand_path('../../..', __dir__)
      config.provider_dirs = [File.join('lib', 'inferno', 'config', 'boot')]
      config.component_dirs.add 'lib'
    end
  end
end
