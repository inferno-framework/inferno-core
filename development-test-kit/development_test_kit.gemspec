require_relative 'lib/development_test_kit/version'

Gem::Specification.new do |spec|
  spec.name          = 'development_test_kit'
  spec.version       = DevelopmentTestKit::VERSION
  spec.authors       = ['rscanlon']
  # spec.email         = ['TODO']
  spec.summary       = 'Development Test Kit'
  # spec.description   = <<~DESCRIPTION
  #   This is a big markdown description of the test kit.
  # DESCRIPTION
  # spec.homepage      = 'TODO'
  spec.license       = 'Apache-2.0'
  spec.add_dependency 'inferno_core'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.3.6')
  spec.metadata['inferno_test_kit'] = 'true'
  # spec.metadata['homepage_uri'] = spec.homepage
  # spec.metadata['source_code_uri'] = 'TODO'
  spec.files         = Dir.glob('{lib,config/presets}/**/*') + ['LICENSE']

  spec.require_paths = ['lib']
end
