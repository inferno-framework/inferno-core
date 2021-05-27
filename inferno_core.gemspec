# frozen_string_literal: true

require_relative 'lib/inferno/version'
require 'rake'

Gem::Specification.new do |spec|
  spec.name          = 'inferno_core'
  spec.version       = Inferno::VERSION
  spec.authors       = ['Stephen MacVicar']
  spec.email         = ['smacvicar@mitre.org']
  spec.date          = Time.now.utc.strftime('%Y-%m-%d')
  spec.summary       = 'Inferno Core is an open source tool for testing data exchanges enabled by the FHIR standand'
  spec.description   = 'Inferno Core is an open source tool for testing data exchanges enabled by the FHIR standand'
  spec.homepage      = 'https://github.com/inferno_community/inferno-core'
  spec.license       = 'Apache 2.0'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'blueprinter'
  spec.add_runtime_dependency 'dotenv'
  spec.add_runtime_dependency 'dry-system', '0.18.1'
  spec.add_runtime_dependency 'faraday'
  spec.add_runtime_dependency 'fhir_client'
  spec.add_runtime_dependency 'hanami-controller', '~> 1.3'
  spec.add_runtime_dependency 'hanami-router', '~> 1.3'
  # spec.add_runtime_dependency 'health_cards' # TODO: remove
  spec.add_runtime_dependency 'oj'
  spec.add_runtime_dependency 'pry'
  spec.add_runtime_dependency 'pry-byebug'
  spec.add_runtime_dependency 'puma'
  spec.add_runtime_dependency 'rake'
  spec.add_runtime_dependency 'sequel'
  spec.add_runtime_dependency 'sqlite3'
  spec.add_development_dependency 'codecov'
  spec.add_development_dependency 'database_cleaner-sequel'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop', '~> 1.9'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'rubocop-sequel'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'yard'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/inferno_community/inferno-core'
  spec.metadata['changelog_uri'] = 'https://github.com/dvci/health_cards/CHANGELOG.md'
  spec.files = [
    'lib/inferno.rb',
    'LICENSE.txt',
    Dir['lib/inferno/**/*.rb'],
    Dir['bin/**/*'],
    Dir['lib/inferno/public/*.png'],
    Dir['lib/inferno/public/*.ico'],
    Dir['lib/inferno/public/*.js'],
    Dir['lib/inferno/public/bundle.js.LICENSE.txt'],
    Dir['lib/inferno/public/assets.json']
  ].flatten

  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
