require_relative 'inferno/config/application'
require_relative 'inferno/dsl'
require_relative 'inferno/entities'
require_relative 'inferno/exceptions'
require_relative 'inferno/jobs'
require_relative 'inferno/repositories'
require_relative 'inferno/spec_support'
require_relative 'inferno/test_runner'
require_relative 'inferno/version'
require_relative 'inferno/utils/static_assets'

module Inferno
  def self.routes
    @routes ||= []
  end
end
