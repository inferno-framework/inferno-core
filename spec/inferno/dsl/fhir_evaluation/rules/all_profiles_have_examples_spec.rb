# frozen_string_literal: true

require 'extract_tgz_helper'
require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluator'
require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllProfilesHaveExamples do
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

  it 'can recognize profiles used by meta.profile' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json',
      'StructureDefinition-us-core-encounter.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, profiles:)
    data = [patient85]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, Inferno::DSL::FHIREvaluation::Config.new,
                                                                  nil)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq('All profiles have examples.')
  end

  it 'can recognize unused profiles by meta.profile' do
    profiles_to_load = [
      'StructureDefinition-us-core-practitioner.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, profiles:)
    data = [patient85]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, Inferno::DSL::FHIREvaluation::Config.new,
                                                                  nil)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq("Found profiles without examples: \n\t http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner")
  end
end
