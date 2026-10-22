RSpec.describe Inferno::DSL::FHIRResourceValidation do
  let(:validation_url) { 'http://example.com' }
  let(:canonical_base) { 'http://hl7.org/fhir/us/core/' }
  let(:profile_url) { "#{canonical_base}StructureDefinition/us-core-patient" }
  let(:validator) do
    Inferno::DSL::FHIRResourceValidation::Validator.new('pinned', 'test_suite') do
      url 'http://example.com'
      igs 'fhir.onc.us-quality-core#0.5.0'
      pin_profile_version 'http://hl7.org/fhir/us/core/', '6.1.0'
      pin_profile_version 'http://fhir.org/guides/onc/us-quality-core/', '0.5.0'
    end
  end
  let(:runnable) { Inferno::Entities::Test.new }
  let(:resource) { FHIR::Patient.new }
  let(:response_body) { { outcomes: [{ issues: [] }] }.to_json }

  before do
    allow(Inferno::Feature).to receive(:use_validation_context_key?).and_return(true)
    stub_request(:post, "#{validation_url}/validate").to_return(status: 200, body: response_body)
  end

  def expect_profile_sent(expected_profile, context_key: 'validationContext')
    expect(WebMock).to(have_requested(:post, "#{validation_url}/validate").with do |request|
      body = JSON.parse(request.body)
      body.fetch(context_key).fetch('profiles') == [expected_profile]
    end)
  end

  describe '#pin_profile_version' do
    [true, false].each do |feature_flag|
      it "pins outgoing profiles when use_validation_context_key? is #{feature_flag}" do
        allow(Inferno::Feature).to receive(:use_validation_context_key?).and_return(feature_flag)

        expect(validator.resource_is_valid?(resource, profile_url, runnable)).to be(true)

        expect_profile_sent("#{profile_url}|6.1.0", context_key: feature_flag ? 'validationContext' : 'cliContext')
      end
    end

    it 'pins Quality Core profiles to their own declared version' do
      quality_core_profile = 'http://fhir.org/guides/onc/us-quality-core/StructureDefinition/us-quality-core-patient'

      validator.resource_is_valid?(resource, quality_core_profile, runnable)

      expect_profile_sent("#{quality_core_profile}|0.5.0")
    end

    it 'pins an explicitly requested base FHIR profile' do
      validator.pin_profile_version('http://hl7.org/fhir/StructureDefinition/', '4.0.1')

      expect(validator.resource_is_valid?(resource, 'http://hl7.org/fhir/StructureDefinition/Patient', runnable))
        .to be(true)

      expect_profile_sent('http://hl7.org/fhir/StructureDefinition/Patient|4.0.1')
    end

    it 'pins the default base FHIR profile when no profile URL is supplied' do
      validator.pin_profile_version('http://hl7.org/fhir/StructureDefinition/', '4.0.1')

      expect(validator.resource_is_valid?(resource, nil, runnable)).to be(true)

      expect_profile_sent('http://hl7.org/fhir/StructureDefinition/Patient|4.0.1')
    end

    it 'keeps the base FHIR pin separate from IG profile versions' do
      validator.pin_profile_version('http://hl7.org/fhir/StructureDefinition/', '4.0.1')
      other_profile = 'http://hl7.org/fhir/us/example/StructureDefinition/patient'

      validator.resource_is_valid?(resource, profile_url, runnable)
      validator.resource_is_valid?(resource, other_profile, runnable)

      expect_profile_sent("#{profile_url}|6.1.0")
      expect_profile_sent(other_profile)
    end

    it 'preserves an explicitly requested version even when it differs from the configured pin' do
      validator.resource_is_valid?(resource, "#{profile_url}|7.0.0", runnable)

      expect_profile_sent("#{profile_url}|7.0.0")
    end

    it 'leaves unmatched URLs unchanged, including similar namespaces' do
      other_profile = 'http://hl7.org/fhir/us/core-other/StructureDefinition/patient'

      validator.resource_is_valid?(resource, other_profile, runnable)

      expect_profile_sent(other_profile)
    end

    it 'does not pin profiles when no pins are configured' do
      unpinned_validator = Inferno::DSL::FHIRResourceValidation::Validator.new { url 'http://example.com' }

      unpinned_validator.resource_is_valid?(resource, profile_url, runnable)

      expect_profile_sent(profile_url)
    end

    it 'accepts bases without trailing slashes' do
      validator.pin_profile_version('http://example.org/fhir', '2.0.0')
      other_profile = 'http://example.org/fhir/StructureDefinition/patient'

      validator.resource_is_valid?(resource, other_profile, runnable)

      expect_profile_sent("#{other_profile}|2.0.0")
    end

    it 'uses the most specific base when configured namespaces overlap' do
      validator.pin_profile_version('http://hl7.org/fhir/', '4.0.1')

      validator.resource_is_valid?(resource, profile_url, runnable)

      expect_profile_sent("#{profile_url}|6.1.0")
    end

    it 'does not change the IGs or send pin configuration to the Java validator' do
      original_context = validator.validation_context.definition.deep_dup

      validator.resource_is_valid?(resource, profile_url, runnable)

      expect(validator.validation_context.definition).to eq(original_context)
      expect(WebMock).to(have_requested(:post, "#{validation_url}/validate").with do |request|
        JSON.parse(request.body).fetch('validationContext') == original_context.deep_stringify_keys.merge(
          'profiles' => ["#{profile_url}|6.1.0"]
        )
      end)
    end

    it 'does not modify the resource or the supplied profile string' do
      original_resource = resource.to_json
      original_profile = profile_url.dup

      validator.resource_is_valid?(resource, profile_url.freeze, runnable)

      expect(resource.to_json).to eq(original_resource)
      expect(profile_url).to eq(original_profile)
    end

    it 'keeps pins isolated between suite validators' do
      other_validator = Inferno::DSL::FHIRResourceValidation::Validator.new('other', 'other_suite') do
        url 'http://example.com'
        pin_profile_version 'http://hl7.org/fhir/us/core/', '9.0.0'
      end

      other_validator.resource_is_valid?(resource, profile_url, runnable)
      validator.resource_is_valid?(resource, profile_url, runnable)

      expect_profile_sent("#{profile_url}|9.0.0")
      expect_profile_sent("#{profile_url}|6.1.0")
    end

    it 'passes the effective version to additional validation callbacks' do
      validated_profile = nil
      validator.perform_additional_validation do |_target, profile|
        validated_profile = profile
        nil
      end

      validator.resource_is_valid?(resource, profile_url, runnable)

      expect(validated_profile).to eq("#{profile_url}|6.1.0")
    end

    it 'pins direct validate calls as well as resource validation' do
      expect(validator.validate(resource, profile_url)).to eq(response_body)

      expect_profile_sent("#{profile_url}|6.1.0")
    end

    it 'pins logical-model validation requests' do
      validator.conforms_to_logical_model?({ 'resourceType' => 'Patient' }, profile_url, runnable)

      expect_profile_sent("#{profile_url}|6.1.0")
    end

    it 'allows repeated declarations of the same pin' do
      expect { validator.pin_profile_version(canonical_base.delete_suffix('/'), '6.1.0') }.to_not raise_error
    end

    it 'rejects conflicting pins for the same normalized base' do
      expect { validator.pin_profile_version(canonical_base.delete_suffix('/'), '9.0.0') }
        .to raise_error(ArgumentError, /Conflicting profile versions/)
    end

    [nil, '', ' ', 'http://example.org|1.0', 'http://example.org#fragment',
     'http://example.org/space here'].each do |base|
      it "rejects an invalid canonical base #{base.inspect}" do
        expect { validator.pin_profile_version(base, '1.0.0') }.to raise_error(ArgumentError, /canonical_base/)
      end
    end

    [nil, '', ' ', '1|2', '1#fragment', '1 2'].each do |version|
      it "rejects an invalid version #{version.inspect}" do
        expect { validator.pin_profile_version(canonical_base, version) }.to raise_error(ArgumentError, /version/)
      end
    end
  end

  describe '#versioned_profile_url' do
    it 'preserves canonical fragment formatting without validating the target' do
      validator.pin_profile_version('http://fhir.acme.com/', '1.0')

      expect(validator.versioned_profile_url('http://fhir.acme.com/Questionnaire/example#vs1'))
        .to eq('http://fhir.acme.com/Questionnaire/example|1.0#vs1')
    end
  end

  describe '#pin_profile_versions' do
    let(:validator) do
      Inferno::DSL::FHIRResourceValidation::Validator.new('pinned', 'test_suite') do
        url 'http://example.com'
        igs 'fhir.onc.us-quality-core#0.5.0'
        pin_profile_versions(
          'http://fhir.org/guides/onc/us-quality-core/' => '0.5.0',
          'http://hl7.org/fhir/us/core/' => '6.1.0'
        )
      end
    end

    it 'pins requests for each canonical base in the hash' do
      quality_core_profile = 'http://fhir.org/guides/onc/us-quality-core/StructureDefinition/us-quality-core-patient'

      validator.resource_is_valid?(resource, profile_url, runnable)
      validator.resource_is_valid?(resource, quality_core_profile, runnable)

      expect_profile_sent("#{profile_url}|6.1.0")
      expect_profile_sent("#{quality_core_profile}|0.5.0")
      expect(validator.igs).to eq(['fhir.onc.us-quality-core#0.5.0'])
    end

    it 'preserves explicit profile versions' do
      validator.resource_is_valid?(resource, "#{profile_url}|7.0.0", runnable)

      expect_profile_sent("#{profile_url}|7.0.0")
    end

    it 'adds to pins declared through either form' do
      validator.pin_profile_version('http://example.org/fhir/', '2.0.0')
      validator.pin_profile_versions('http://example.org/other/' => '3.0.0')

      validator.resource_is_valid?(resource, 'http://example.org/fhir/StructureDefinition/patient', runnable)
      validator.resource_is_valid?(resource, 'http://example.org/other/StructureDefinition/patient', runnable)
      validator.resource_is_valid?(resource, profile_url, runnable)

      expect_profile_sent('http://example.org/fhir/StructureDefinition/patient|2.0.0')
      expect_profile_sent('http://example.org/other/StructureDefinition/patient|3.0.0')
      expect_profile_sent("#{profile_url}|6.1.0")
    end

    it 'rejects conflicting versions across the two declaration forms' do
      validator.pin_profile_version('http://example.org/fhir/', '2.0.0')

      expect { validator.pin_profile_versions('http://example.org/fhir' => '3.0.0') }
        .to raise_error(ArgumentError, /Conflicting profile versions/)
    end

    it 'rejects invalid entries using the singular directive rules' do
      expect { validator.pin_profile_versions('' => '1.0.0') }.to raise_error(ArgumentError, /canonical_base/)
      expect { validator.pin_profile_versions('http://example.org/fhir/' => '') }
        .to raise_error(ArgumentError, /version/)
    end

    it 'accepts a frozen hash without modifying it' do
      pins = { 'http://example.org/fhir/' => '2.0.0' }.freeze

      validator.pin_profile_versions(pins)

      expect(pins).to eq('http://example.org/fhir/' => '2.0.0')
      validator.resource_is_valid?(resource, 'http://example.org/fhir/StructureDefinition/patient', runnable)
      expect_profile_sent('http://example.org/fhir/StructureDefinition/patient|2.0.0')
    end

    it 'accepts an empty hash without clearing existing pins' do
      validator.pin_profile_versions({})
      validator.resource_is_valid?(resource, profile_url, runnable)

      expect_profile_sent("#{profile_url}|6.1.0")
    end

    [nil, [], '6.1.0'].each do |versions|
      it "rejects a non-hash argument #{versions.inspect}" do
        expect { validator.pin_profile_versions(versions) }.to raise_error(ArgumentError, /must be a hash/)
      end
    end
  end
end
