# frozen_string_literal: true

require 'extract_tgz_helper'
require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::DifferentialContentHasExamples do
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

  it 'collects differential content on a profile' do
    profiles_to_load = [
      'StructureDefinition-us-core-medication.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    # https://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-medication.html
    expected_differential = { 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication' => ['code'] }

    differential = Hash.new { |h, k| h[k] = Set.new }
    described_class.new.collect_profile_differential_content(differential, profiles)

    expect(differential).to include(expected_differential)
  end

  it 'collects differential content on an extension' do
    extensions_to_load = [
      'StructureDefinition-us-core-race.json'
    ]
    extensions = extensions_to_load.map { |e| fixture(e.to_s) }
    # https://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-race.html
    expected_differential = { 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race' => ['extension', 'extension.url', 'extension.valueCoding', 'extension.valueString', 'url'] }

    differential = Hash.new { |h, k| h[k] = Set.new }
    described_class.new.collect_profile_differential_content(differential, extensions)

    expect(differential).to include(expected_differential)
  end

  it 'identifies used differential content' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, profiles:, extensions: [])
    data = [patient85.entry[0].resource]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil,
                                                                  Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    # expect(result.severity).to eq('success')
    expect(result.message).to eq('All differential fields are used in examples.')
  end

  it 'identifies unused differential content' do
    profiles_to_load = [
      'StructureDefinition-us-core-medication.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    # https://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-medication.html
    ig = instance_double(Inferno::Entities::IG, profiles:, extensions: [])
    data = [FHIR::Medication.new]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil,
                                                                  Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    # rubocop:disable Layout/LineLength
    expect(result.message).to eq("Found fields highlighted in the differential view, but not used in examples: \n Profile/Extension: http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication  \n\tFields: code")
    # rubocop:enable Layout/LineLength
  end
end
