require 'active_support/all'
require 'dotenv'
require 'dry/system/container'
require 'sequel'
require_relative 'boot'

module Inferno
  class Application < Dry::System::Container
    ::Inferno::Import = injector

    use :env, inferrer: -> { ENV.fetch('APP_ENV', :development).to_sym }

    Application.register('js_host', ENV.fetch('JS_HOST', ''))
    Application.register('base_path', ENV.fetch('BASE_PATH', ''))
    Application.register('async_jobs', ENV['ASYNC_JOBS'] != 'false')
    Application.register('inferno_host', ENV.fetch('INFERNO_HOST', 'http://localhost:4567'))
    Application.register('base_url', URI::join(Application['inferno_host'], Application['base_path']).to_s)

    configure do |config|
      config.root = File.expand_path('../../..', __dir__)
      config.default_namespace = 'inferno'
      config.system_dir = File.join('lib', 'inferno', 'config')
      config.bootable_dirs = [File.join('lib', 'inferno', 'config', 'boot')]

      config.auto_register = 'lib'
    end

    load_paths!('lib')
  end
end
