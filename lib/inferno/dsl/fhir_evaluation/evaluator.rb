# frozen_string_literal: true

require_relative 'config'
require_relative 'rule'
require_relative 'evaluation_context'
require_relative 'evaluation_result'
require_relative 'dataset_loader'
require_relative 'rules/all_must_supports_present'

module Inferno
  module DSL
    module FHIREvaluation
      class Evaluator
        attr_accessor :ig, :validator

        def initialize(ig, validator = nil)
          @ig = ig
          @validator = validator
        end

        def evaluate(data, config = Config.new)
          context = EvaluationContext.new(@ig, data, config, validator)

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
