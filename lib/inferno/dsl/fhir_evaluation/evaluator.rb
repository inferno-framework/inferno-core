# frozen_string_literal: true

require_relative 'config'
require_relative 'rule'
require_relative 'evaluation_context'
require_relative 'evaluation_result'
require_relative 'dataset_loader'

Dir.glob(File.join(__dir__, 'rules', '*.rb')).each do |file|
  require_relative file
end

module Inferno
  module DSL
    module FHIREvaluation
      class Evaluator
        attr_accessor :ig

        def initialize(ig) # rubocop:disable Naming/MethodParameterName
          @ig = ig
        end

        def evaluate(data, config = Config.new)
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
