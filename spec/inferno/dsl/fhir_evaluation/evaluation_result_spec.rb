RSpec.describe Inferno::DSL::FHIREvaluation::EvaluationResult do
  let(:threshold_url) do
    'https://inferno-framework.github.io/fhir_evaluator/StructureDefinition/operationoutcome-issue-threshold'
  end
  let(:value_url) do
    'https://inferno-framework.github.io/fhir_evaluator/StructureDefinition/operationoutcome-issue-value'
  end

  describe '#to_s' do
    it 'includes the upcased severity and the message' do
      expect(described_class.new('Something happened', severity: 'error').to_s).to eq('ERROR: Something happened')
    end
  end

  describe '#to_oo_issue' do
    it 'builds an issue with no extensions when there is no threshold or value' do
      issue = described_class.new('A message').to_oo_issue

      expect(issue).to eq(severity: 'warning', code: 'business-rule', details: { text: 'A message' })
    end

    it 'adds threshold and value extensions when present' do
      issue = described_class.new('A message', severity: 'information', issue_type: 'informational',
                                               threshold: 0.5, value: 0.25).to_oo_issue

      expect(issue[:severity]).to eq('information')
      expect(issue[:code]).to eq('informational')
      expect(issue[:extension]).to eq(
        [
          { url: threshold_url, valueDecimal: 0.5 },
          { url: value_url, valueDecimal: 0.25 }
        ]
      )
    end

    it 'adds only a value extension when there is no threshold' do
      issue = described_class.new('A message', value: 3).to_oo_issue

      expect(issue[:extension]).to eq([{ url: value_url, valueDecimal: 3 }])
    end
  end

  describe '.to_operation_outcome' do
    it 'builds an OperationOutcome with an issue for each result' do
      results = [
        described_class.new('First', severity: 'error'),
        described_class.new('Second', severity: 'success', threshold: 1)
      ]

      outcome = described_class.to_operation_outcome(results)

      expect(outcome).to be_a(FHIR::OperationOutcome)
      expect(outcome.issue.map(&:severity)).to eq(['error', 'success'])
      expect(outcome.issue.map { |issue| issue.details.text }).to eq(['First', 'Second'])
      expect(outcome.issue.last.extension.first.url).to eq(threshold_url)
    end
  end
end
