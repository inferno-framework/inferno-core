# frozen_string_literal: true

module FhirEvaluator
  class Evaluator
    def initialize(the_ig)
      @ig = the_ig
    end

    def evaluate(data, summary = nil, config = Config.new)
      summary ||= DataSummary.new(data)
      context = EvaluationContext.new(@ig, data, summary, config)

      active_rules = []
      config.data['Rule'].each_key do |rulename|
        active_rules << rulename if config.data['Rule'][rulename]['Enabled']
      end

      Rule.descendants.each do |rule|
        rule.new.check(context) if active_rules.include?(rule.name.gsub('FhirEvaluator::Rules::', ''))
      end

      context.results
    end
  end
end
