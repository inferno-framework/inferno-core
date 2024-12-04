# frozen_string_literal: true

module FhirEvaluator
  class Evaluator
    def initialize(the_ig)
      @ig = the_ig
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
