require_relative '../../../lib/inferno/dsl/fhir_resource_navigation'

RSpec.describe Inferno::DSL::FHIRResourceNavigation do
  # Using a new class to perform navigation in order to have access to metadata.
  let(:including_class) do
    Class.new do
      include Inferno::DSL::FHIRResourceNavigation
      attr_accessor :metadata
    end
  end
  let(:must_support_coverage_test) do
    # originally, USCoreTestKit::USCoreV610::CoverageMustSupportTest.new
    msc_test = including_class.new
    msc_test.metadata = metadata_fixture('coverage_v610.yml')
    msc_test
  end
  let(:must_support_heartrate_test) do
    # originally, USCoreTestKit::USCoreV610::HeartRateMustSupportTest.new
    mshr_test = including_class.new
    mshr_test.metadata = metadata_fixture('heart_rate_v610.yml')
    mshr_test
  end
  let(:coverage_with_two_classes) do
    FHIR::Coverage.new.tap do |cov|
      cov.local_class = [FHIR::Coverage::Class.new.tap do |loc_class|
        loc_class.type = FHIR::CodeableConcept.new.tap do |code_concept|
          code_concept.coding = [FHIR::Coding.new.tap do |coding|
            coding.system = 'http://terminology.hl7.org/CodeSystem/coverage-class'
            coding.code = 'group'
          end]
        end
        loc_class.value = 'groupclass'
      end,
                         FHIR::Coverage::Class.new.tap do |loc_class|
                           loc_class.type = FHIR::CodeableConcept.new.tap do |code_concept|
                             code_concept.coding = [FHIR::Coding.new.tap do |coding|
                               coding.system = 'http://terminology.hl7.org/CodeSystem/coverage-class'
                               coding.code = 'plan'
                             end]
                           end
                           loc_class.value = 'planclass'
                         end]
      cov.identifier = [FHIR::Identifier.new.tap do |identifier|
        identifier.type = FHIR::CodeableConcept.new.tap do |code_concept|
          code_concept.coding = [FHIR::Coding.new.tap do |coding|
            coding.system = 'http://terminology.hl7.org/CodeSystem/v2-0203'
            coding.code = 'MB'
          end]
        end
        identifier.system = 'https://github.com/inferno-framework/us-core-test-kit'
        identifier.value = 'f4a375d2-4e53-4f81-ba95-345e7573b550'
      end]
    end
  end
  let(:heartrate_by_value) do
    FHIR::Observation.new.tap do |observation|
      observation.category = [FHIR::CodeableConcept.new.tap do |code_concept|
        code_concept.coding = [FHIR::Coding.new.tap do |code|
          code.system = 'something-else'
          code.code = 'vital-signs'
        end]
        code_concept.text = 'heartrate-example-wrong-system'
      end,
                              FHIR::CodeableConcept.new.tap do |code_concept|
                                code_concept.coding = [FHIR::Coding.new.tap do |code|
                                  code.system = 'http://terminology.hl7.org/CodeSystem/observation-category'
                                  code.code = 'something-else'
                                end]
                                code_concept.text = 'heartrate-example-wrong-code'
                              end,
                              FHIR::CodeableConcept.new.tap do |code_concept|
                                code_concept.coding = [FHIR::Coding.new.tap do |code|
                                  code.system = 'http://terminology.hl7.org/CodeSystem/observation-category'
                                  code.code = 'vital-signs'
                                end]
                                code_concept.text = 'heartrate-example'
                              end]
      observation.valueQuantity = FHIR::Quantity.new.tap do |quantity|
        quantity.value = 44
        quantity.unit = 'beats/min'
        quantity.system = 'http://unitsofmeasure.org'
        quantity.code = '/min'
      end
    end
  end

  def metadata_fixture(filename)
    path = File.realpath(File.join(Dir.pwd, 'spec/fixtures/metadata', filename))
    metadata_yaml = YAML.load_file(path)
    OpenStruct.new(metadata_yaml) # so that the top-level keys can be accessed directly, ie metadata.must_supports[...]
  end

  describe '#resolve_path' do
    it 'gets a value' do
      expect(must_support_coverage_test.resolve_path(heartrate_by_value, 'value.value')).to contain_exactly(44)
    end
  end

  describe '#find_a_value_at' do
    it 'finds the first value when not given a specific slice' do
      expect(must_support_coverage_test.find_a_value_at(coverage_with_two_classes, 'class.value')).to eq('groupclass')
    end

    it 'finds a specific slice value when given a specific slice' do
      expect(must_support_coverage_test.find_a_value_at(coverage_with_two_classes,
                                                        'class:plan.value')).to eq('planclass')
    end

    it 'can find fixed elements given a specific slice' do
      expect(must_support_coverage_test.find_a_value_at(coverage_with_two_classes,
                                                        'identifier:memberid.type.coding.code')).to eq('MB')
    end

    it 'can find an element in a specific slice discriminated by values' do
      expect(must_support_heartrate_test.find_a_value_at(heartrate_by_value,
                                                         'category:VSCat.text')).to eq('heartrate-example')
    end

    it 'can find an element in a specific slice discriminated by type' do
      expect(must_support_heartrate_test.find_a_value_at(heartrate_by_value,
                                                         'value[x]:valueQuantity.code')).to eq('/min')
    end
  end

  describe '#matching_type_slice?' do
    let(:matcher) { including_class.new }

    it 'matches on Date for a valid Date' do
      slice = '2024-05-06'
      discriminator = { code: 'Date' }
      expect(matcher).to be_matching_type_slice(slice, discriminator)
    end

    it 'does not match on Date for an invalid Date' do
      slice = 'hello'
      discriminator = { code: 'Date' }
      expect(matcher).to_not be_matching_type_slice(slice, discriminator)
    end

    it 'matches on DateTime for a valid DateTime' do
      slice = '2024-05-06T07:08:09'
      discriminator = { code: 'DateTime' }
      expect(matcher).to be_matching_type_slice(slice, discriminator)
    end

    it 'does not match on DateTime for an invalid DateTime' do
      slice = 'hello'
      discriminator = { code: 'DateTime' }
      expect(matcher).to_not be_matching_type_slice(slice, discriminator)
    end

    it 'matches on String for a String' do
      slice = 'some value here'
      discriminator = { code: 'String' }
      expect(matcher).to be_matching_type_slice(slice, discriminator)
    end

    it 'does not match on String for a non-String' do
      slice = FHIR::Quantity.new
      discriminator = { code: 'String' }
      expect(matcher).to_not be_matching_type_slice(slice, discriminator)
    end

    it 'matches on other type for the appropriate type' do
      slice = FHIR::Quantity.new
      discriminator = { code: 'Quantity' }
      expect(matcher).to be_matching_type_slice(slice, discriminator)
    end

    it 'does not match on other type for the wrong type' do
      slice = FHIR::Period.new
      discriminator = { code: 'Quantity' }
      expect(matcher).to_not be_matching_type_slice(slice, discriminator)
    end

    it 'matches type slice with path for appropriate type' do
      slice = FHIR::Bundle::Entry.new(
        resource: FHIR::Patient.new
      )
      discriminator = { code: 'Patient', path: 'resource' }
      expect(matcher).to be_matching_type_slice(slice, discriminator)
    end

    it 'deso not matches type slice with path for wrong type' do
      slice = FHIR::Bundle::Entry.new(
        resource: FHIR::Observation.new
      )
      discriminator = { code: 'Patient', path: 'resource' }
      expect(matcher).to_not be_matching_type_slice(slice, discriminator)
    end    
  end
end
