# frozen_string_literal: true

require 'extract_tgz_helper'
require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::ValueSetsDemonstrate do
  include ExtractTGZHelper

  let(:uscore3_package) { File.realpath(File.join(Dir.pwd, 'spec/fixtures/uscore311.tgz')) }
  let(:uscore3_untarred) { extract_tgz(uscore3_package) }

  let(:patient85) do
    path = File.expand_path('../../../../../spec/fixtures/patient_85.json', __dir__)
    FHIR::Json.from_json(File.read(path))
  end

  def fixture(filename)
    path = File.join(uscore3_untarred, 'package', filename)
    FHIR::Json.from_json(File.read(path))
  end

  after { cleanup(uscore3_untarred) }

  # rubocop:disable Layout/LineLength
  it 'identifies used valuesets' do
    value_sets_to_load = ['ValueSet-us-core-observation-smokingstatus.json']
    value_sets = value_sets_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, value_sets:)
    smoking_status_obs = patient85.entry.map(&:resource).find do |r|
      r.resourceType == 'Observation' && r.code.text == 'Tobacco smoking status'
    end
    data = [smoking_status_obs]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data,
                                                                  Inferno::DSL::FHIREvaluation::Config.new, nil)

    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-smoking-status-observation-codes').to_return(
      status: 200, body: '', headers: {}
    )

    result = described_class.new.check(context)[0]
    expect(result.severity).to eq('success')
    expect(result.message).to eq("All ValueSets are used in examples:\n\thttp://hl7.org/fhir/us/core/ValueSet/us-core-observation-smokingstatus is used 1 times in 1 resources")
  end

  it 'identifies unused valuesets' do
    value_sets_to_load = [
      'ValueSet-us-core-observation-smokingstatus.json'
    ]
    value_sets = value_sets_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, value_sets:)
    data = [FHIR::Observation.new]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.severity).to eq('warning')
    expect(result.message).to eq("Found ValueSets with all codes used (at least once) in examples:\nFound unused ValueSets: \n\thttp://hl7.org/fhir/us/core/ValueSet/us-core-observation-smokingstatus")
  end
  # rubocop:enable Layout/LineLength
end
