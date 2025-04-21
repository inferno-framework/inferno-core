# frozen_string_literal: true

require 'extract_tgz_helper'
require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

# rubocop:disable Layout/LineLength
RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllExtensionsUsed do
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

  it 'collects extensions on a profile' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    # https://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-patient.html
    expected_extension_urls = { 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient' =>
      [
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex'
      ] }

    found_extensions = described_class.new.collect_profile_extensions(profiles)

    expect(found_extensions).to include(expected_extension_urls)
  end

  it 'identifies used extensions' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, profiles:)
    data = [patient85.entry[0].resource]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil,
                                                                  Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    # expect(result.severity).to eq('success')
    expect(result.message).to eq('All extensions specified in profiles are used in examples.')
  end

  it 'identifies unused extensions' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, profiles:)
    data = [FHIR::Patient.new(meta: { profile: ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'] })]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil,
                                                                  Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq("Found extensions specified in profiles, but NOT used in examples:\n Profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient, \n\tExtensions: http://hl7.org/fhir/us/core/StructureDefinition/us-core-race, http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity, http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex")

    data = [FHIR::Patient.new(meta: { profile: ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'] },
                              extension: [{
                                url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex', valueCode: 'female'
                              }])]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil,
                                                                  Inferno::DSL::FHIREvaluation::Config.new)
    result2 = described_class.new.check(context)[0]

    expect(result2.message).to eq("Found extensions specified in profiles, but NOT used in examples:\n Profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient, \n\tExtensions: http://hl7.org/fhir/us/core/StructureDefinition/us-core-race, http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity")
  end
end
# rubocop:enable Layout/LineLength
