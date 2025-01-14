# frozen_string_literal: true

require_relative 'lib/inferno/version'

Gem::Specification.new do |spec|
  spec.name          = 'inferno_core'
  spec.version       = Inferno::VERSION
  spec.authors       = ['Stephen MacVicar', 'Robert Scanlon', 'Chase Zhou']
  spec.email         = ['inferno@groups.mitre.org']
  spec.summary       = 'Inferno Core is an open source tool for testing data exchanges enabled by the FHIR standand'
  spec.description   = 'Inferno Core is an open source tool for testing data exchanges enabled by the FHIR standand'
  spec.homepage      = 'https://github.com/inferno-framework/inferno-core'
  spec.license       = 'Apache-2.0'
  spec.add_dependency 'activesupport', '~> 6.1.7.5'
  spec.add_dependency 'base62-rb', '0.3.1'
  spec.add_dependency 'blueprinter', '0.25.2'
  spec.add_dependency 'dotenv', '~> 2.7'
  spec.add_dependency 'dry-configurable', '1.0.0'
  spec.add_dependency 'dry-container', '0.10.0'
  spec.add_dependency 'dry-core', '1.0.0'
  spec.add_dependency 'dry-inflector', '1.0.0'
  spec.add_dependency 'dry-system', '1.0.0'
  spec.add_dependency 'faraday', '~> 1.2'
  spec.add_dependency 'faraday_middleware', '~> 1.2'
  spec.add_dependency 'fhir_client', '>= 5.0.3'
  spec.add_dependency 'fhir_models', '>= 4.2.2'
  spec.add_dependency 'hanami-controller', '2.0.0'
  spec.add_dependency 'hanami-router', '2.0.0'
  spec.add_dependency 'oj', '3.11.0'
  spec.add_dependency 'pastel', '~> 0.8.0'
  spec.add_dependency 'pry'
  spec.add_dependency 'pry-byebug'
  spec.add_dependency 'puma', '~> 5.6.7'
  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'sequel', '~> 5.42.0'
  spec.add_dependency 'sidekiq', '~> 7.2.4'
  spec.add_dependency 'sqlite3', '~> 1.4'
  spec.add_dependency 'thor', '~> 1.2.1'
  spec.add_dependency 'tty-markdown', '~> 0.7.1'
  spec.required_ruby_version = Gem::Requirement.new('~> 3.1.2')
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/inferno-framework/inferno-core'
  spec.metadata['changelog_uri'] = 'https://github.com/inferno-framework/inferno-core/blob/main/CHANGELOG.md'
  spec.files = [
    'lib/inferno.rb',
    'LICENSE',
    Dir['lib/inferno/**/*.rb'],
    Dir['lib/inferno/**/*.erb'],
    Dir['lib/inferno/**/*.json'],
    Dir['lib/inferno/apps/cli/templates/**/{*,.*}'],
    'bin/inferno',
    Dir['lib/inferno/public/*.png'],
    Dir['lib/inferno/public/*.ico'],
    Dir['lib/inferno/public/*.js'],
    'lib/inferno/public/bundle.js.LICENSE.txt',
    'lib/inferno/public/assets.json',
    'spec/support/factory_bot.rb',
    Dir['spec/factories/**/*.rb'],
    Dir['spec/fixtures/**/*.rb'],
    Dir['spec/shared/**/*.rb'],
    Dir['spec/*.rb']
  ].flatten

  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib', 'spec']
end
