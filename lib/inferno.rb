require 'active_support/all'
require 'dotenv'
require 'dry/system/container'
require 'sequel'
require_relative 'inferno/config/application'
require_relative 'inferno/dsl'
require_relative 'inferno/entities'
require_relative 'inferno/exceptions'
require_relative 'inferno/repositories'
require_relative 'inferno/spec_support'
require_relative 'inferno/test_runner'
require_relative 'inferno/version'

module Inferno
  def self.routes
    @routes ||= []
  end
end
