require_relative 'boot'

module Inferno
  class Application < Dry::System::Container
    use :env, inferrer: -> { ENV.fetch('APP_ENV', :development).to_sym }

    configure do |config|
      config.root = File.expand_path('../../..', __dir__)
      config.default_namespace = 'inferno'
      config.system_dir = File.join('lib', 'inferno', 'config')
      config.bootable_dirs = [File.join('lib', 'inferno', 'config', 'boot')]

      config.auto_register = 'lib'
    end

    Application.register('js_host', ENV.fetch('JS_HOST', ''))

    load_paths!('lib')
  end

  Import = Application.injector
end
