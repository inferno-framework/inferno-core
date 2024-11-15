module FhirEvaluator
  # The result of a Rule evaluating a data set.
  class EvaluationResult
    attr_accessor :message,
                  :severity,   # fatal | error | warning | information | success
                  :issue_type, # https://www.hl7.org/fhir/valueset-issue-type.html
                  :threshold,  # quantitative value that a rule checks for
                  :value,      # actual observed value
                  :rule        # Rule that produced this result

    def initialize(message, severity: 'warning', issue_type: 'business-rule', threshold: nil, value: nil, rule: nil)
      @message = message
      @severity = severity
      @issue_type = issue_type
      @threshold = threshold
      @value = value
      @rule = rule
    end

    def to_s
      "#{severity.upcase}: #{message}"
    end

    def to_oo_issue
      issue = {
        severity:,
        code: issue_type,
        details: { text: message }
      }

      if threshold
        issue[:extension] ||= []
        issue[:extension].push({
                                 # TODO: pick real extension for this
                                 url: 'https://inferno-framework.github.io/fhir_evaluator/StructureDefinition/operationoutcome-issue-threshold',
                                 valueDecimal: threshold
                               })
      end

      if value
        issue[:extension] ||= []
        issue[:extension].push({
                                 # TODO: pick real extension for this
                                 url: 'https://inferno-framework.github.io/fhir_evaluator/StructureDefinition/operationoutcome-issue-value',
                                 valueDecimal: value
                               })
      end

      issue
    end

    def self.to_operation_outcome(results)
      FHIR::OperationOutcome.new({
                                   issue: results.map(&:to_oo_issue)
                                 })
    end
  end
end
