# frozen_string_literal: true

require 'dotenv'
require 'faraday'
require 'fhir_models'
require 'thor'
require 'erb'
require 'yaml'
require 'pathname'

require_relative 'config'
require_relative 'rule'
require_relative 'evaluation_context'
require_relative 'evaluation_result'
require_relative 'dataset_loader'

module Inferno
  module DSL
    module FHIREvaluation
      class Evaluator
        attr_accessor :data, :config

        def initialize(data, config)
          @data = data
          @config = config
        end

        def evaluate
          context = EvaluationContext.new(@ig, data, config)

          active_rules = []
          config.data['Rule'].each do |rulename, rule_details|
            active_rules << rulename if rule_details['Enabled']
          end

          Rule.descendants.each do |rule|
            rule.new.check(context) if active_rules.include?(rule.name.demodulize)
          end

          context.results
        end
      end
    end
  end
end
