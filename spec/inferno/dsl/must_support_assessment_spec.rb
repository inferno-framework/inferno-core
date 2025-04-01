RSpec.describe Inferno::DSL::MustSupportAssessment do
  include ExtractTGZHelper

  let(:test_impl) do
    uscore3_package = File.expand_path('../../fixtures/uscore311.tgz', __dir__)
    Class.new(Inferno::Entities::Test) do
      fhir_resource_validator { igs(uscore3_package) }
    end.new
  end

  let(:uscore3_package) { File.realpath(File.join(Dir.pwd, 'spec/fixtures/uscore311.tgz')) }
  let(:patient_ref) { 'Patient/85' }
  let(:patient) do
    FHIR::Patient.new(
      meta: { profile: ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'] },
      identifier: [{ system: 'system', value: 'value' }],
      name: [{ use: 'old', family: 'family', given: ['given'], suffix: ['suffix'], period: { end: '2022-12-12' } }],
      telecom: [{ system: 'phone', value: 'value', use: 'home' }],
      gender: 'male',
      birthDate: '2020-01-01',
      deceasedDateTime: '2022-12-12',
      address: [{ use: 'old', line: 'line', city: 'city', state: 'state', postalCode: 'postalCode',
                  period: { start: '2020-01-01' } }],
      communication: [{ language: { text: 'text' } }],
      extension: [
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
          extension: [
            { url: 'ombCategory', valueCoding: { display: 'display' } },
            { url: 'text', valueString: 'valueString' }
          ]
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
          extension: [
            { url: 'ombCategory', valueCoding: { display: 'display' } },
            { url: 'text', valueString: 'valueString' }
          ]
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex',
          valueCode: 'M'
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-tribal-affiliation',
          extension: [{ url: 'tribalAffiliation', valueCodeableConcept: { text: 'text' } }]
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-sex',
          valueCode: 'M'
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-genderIdentity',
          valueCodeableConcept: { text: 'text' }
        }
      ]
    )
  end
  let(:uscore3_untarred) { extract_tgz(uscore3_package) }

  def fixture(filename)
    path = File.join(uscore3_untarred, 'package', filename)
    FHIR::Json.from_json(File.read(path))
  end

  def metadata_fixture(filename)
    path = File.realpath(File.join(Dir.pwd, 'spec/fixtures/metadata', filename))
    metadata_yaml = YAML.load_file(path)
    OpenStruct.new(metadata_yaml) # so that the top-level keys can be accessed directly, ie metadata.must_supports[...]
  end

  after { cleanup(uscore3_untarred) }

  def run(profile, resources, _resource_type, &block)
    test_impl.missing_must_support_elements(resources, profile.url, &block)
  end

  def run_with_metadata(resources, metadata)
    test_impl.missing_must_support_elements(resources, nil, metadata:)
  end

  describe 'must support test for choice elements and regular elements' do
    let(:device_profile) { fixture('StructureDefinition-us-core-implantable-device.json') }
    let(:device) do
      FHIR::Device.new(
        udiCarrier: [{ deviceIdentifier: '43069338026389', carrierHRF: 'carrierHRF' }],
        distinctIdentifier: '43069338026389',
        manufactureDate: '2000-03-02T18:33:18-05:00',
        expirationDate: '2025-03-17T19:33:18-04:00',
        lotNumber: '1134',
        serialNumber: '842026117977',
        type: {
          text: 'Implantable defibrillator, device (physical object)'
        },
        patient: {
          reference: patient_ref
        }
      )
    end

    it 'fails if server supports none of the choice' do
      device.udiCarrier.first.carrierHRF = nil

      result = run(device_profile, [device], 'Device')
      expect(result).to include('udiCarrier.carrierAIDC', 'udiCarrier.carrierHRF')
    end

    it 'fails if server supports only one choice without extra metadata provided' do
      result = run(device_profile, [device], 'Device')
      expect(result).to include('udiCarrier.carrierAIDC')
    end

    it 'passes if server supports at least one of the choice and choice metadata is provided' do
      choices = [{ paths: ['udiCarrier.carrierAIDC', 'udiCarrier.carrierHRF'] }]

      result = run(device_profile, [device], 'Device') do |metadata|
        metadata.must_supports[:choices] = choices
      end
      expect(result).to be_empty
    end

    it 'fails if server does not support one MS element' do
      device.distinctIdentifier = nil

      result = run(device_profile, [device], 'Device')
      expect(result).to include('distinctIdentifier')
    end
  end

  describe 'must support test for extensions' do
    let(:patient_profile) { fixture('StructureDefinition-us-core-patient.json') }

    it 'passes if server suports all MS extensions' do
      result = run(patient_profile, [patient], 'Patient')
      expect(result).to be_empty
    end

    it 'fails if server does not suport one MS extensions' do
      patient.extension.delete_at(0)

      result = run(patient_profile, [patient], 'Patient')
      expect(result).to include('Patient.extension:race')
    end
  end

  describe 'must support test for slices' do
    context 'with patternCodeableConcept slicing' do
      let(:careplan_profile) { fixture('StructureDefinition-us-core-careplan.json') }
      let(:careplan) do
        FHIR::CarePlan.new(
          text: { status: 'status' },
          status: 'status',
          intent: 'intent',
          category: [
            {
              coding: [
                {
                  system: 'http://hl7.org/fhir/us/core/CodeSystem/careplan-category',
                  code: 'assess-plan'
                }
              ]
            }
          ],
          subject: {
            reference: patient_ref
          }
        )
      end

      it 'passes if server suports all MS slices' do
        result = run(careplan_profile, [careplan], 'CarePlan')

        expect(result).to be_empty
      end

      it 'fails if server does not suport one MS extensions' do
        careplan.category.first.coding.first.code = 'something else'

        result = run(careplan_profile, [careplan], 'CarePlan')
        expect(result).to include('CarePlan.category:AssessPlan')
      end
    end

    context 'with patternCodeableConcept slicing and mulitple codings' do
      let(:coverage_metadata) { metadata_fixture('coverage_v610.yml') }
      let(:coverage) do
        FHIR::Coverage.new(
          identifier: [
            {
              system: 'local-id',
              value: '123'
            },
            {
              type: {
                coding: [
                  {
                    system: 'http://terminology.hl7.org/CodeSystem/v2-0203',
                    code: 'MB',
                    display: 'Member Number'
                  }
                ]
              },
              value: 'member-id'
            }
          ],
          status: 'active',
          type: {
            coding: [
              {
                system: 'local-type',
                code: 'medicare'
              }
            ]
          },
          subscriberId: 'abc',
          beneficiary: {
            reference: 'Patient/1'
          },
          relationship: {
            coding: [
              {
                system: 'local-relationship',
                code: '01'
              }
            ]
          },
          period: {
            start: '2022-03-04'
          },
          payor: [
            {
              reference: 'Organization/1'
            }
          ],
          class: [
            {
              type: {
                coding: [
                  {
                    system: 'http://terminology.hl7.org/CodeSystem/coverage-class',
                    code: 'plan'
                  }
                ]
              },
              value: '10603',
              name: 'MEDICARE PART A & B'
            },
            {
              type: {
                coding: [
                  {
                    system: 'http://terminology.hl7.org/CodeSystem/coverage-class',
                    code: 'group'
                  }
                ]
              },
              value: '123',
              name: 'group'
            }
          ]
        )
      end

      it 'passes if server suports all MS slices' do
        result = run_with_metadata([coverage], coverage_metadata)
        expect(result).to be_empty
      end
    end

    context 'with type slicing' do
      let(:smokingstatus_metadata) { metadata_fixture('smokingstatus_v400.yml') }
      let(:observation) do
        FHIR::Observation.new(
          status: 'final',
          category: [
            {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/observation-category',
                  code: 'social-history'
                }
              ]
            }
          ],
          code: {
            coding: [
              {
                system: 'http://loinc.org',
                code: '72166-2'
              }
            ],
            text: 'Tobacco smoking status'
          },
          subject: {
            reference: 'Patient/902'
          },
          effectiveDateTime: '2013-04-23T21:07:05Z',
          valueCodeableConcept: {
            coding: [
              {
                system: 'http://snomed.info/sct',
                code: '449868002'
              }
            ]
          }
        )
      end

      it 'passes if server suports all MS slices' do
        result = run_with_metadata([observation], smokingstatus_metadata)

        expect(result).to be_empty
      end

      it 'skips if datetime format is not correct' do
        observation.effectiveDateTime = 'not a date time'
        result = run_with_metadata([observation], smokingstatus_metadata)

        expect(result).to include('Observation.effective[x]:effectiveDateTime')
      end
    end

    context 'with type slicing on a Bundle' do
      let(:pas_request_bundle_metadata) do
        metadata_fixture('pas_request_bundle_v201.yml')
      end

      let(:pas_request_bundle) do
        FHIR::Bundle.new(
          identifier: {
            system: "http://example.org/SUBMITTER_TRANSACTION_IDENTIFIER",
            value: "16139462398"
          },
          type: 'collection',
          timestamp: '2025-06-24T07:34:00+05:00',
          entry: [
            {
              fullUrl: 'http://example.com/Claim/123',
              resource: FHIR::Claim.new
            }
          ]
        )
      end

      it 'identifies when the slice is present' do
        result = run_with_metadata([pas_request_bundle], pas_request_bundle_metadata)
        expect(result).to be_empty
      end

      it 'identifies when the slice is not present' do
        pas_request_bundle.entry.clear

        result = run_with_metadata([pas_request_bundle], pas_request_bundle_metadata)
        expect(result).to include('Bundle.entry:Claim')
      end
    end

    context 'with requiredBinding slicing' do
      context 'when Condition ProblemsHealthConcerns' do
        let(:condition_problems_health_concerns_metadata) do
          metadata_fixture('condition_problems_health_concerns_v501.yml')
        end
        let(:condition) do
          FHIR::Condition.new(
            extension: [
              {
                url: 'http://hl7.org/fhir/StructureDefinition/condition-assertedDate',
                valueDateTime: '2016-08-10'
              }
            ],
            clinicalStatus: {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/condition-clinical',
                  code: 'active'
                }
              ]
            },
            verificationStatus: {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
                  code: 'confirmed'
                }
              ]
            },
            category: [
              {
                coding: [
                  {
                    system: 'http://terminology.hl7.org/CodeSystem/condition-category',
                    code: 'problem-list-item'
                  }
                ]
              },
              {
                coding: [
                  {
                    system: 'http://hl7.org/fhir/us/core/CodeSystem/us-core-tags',
                    code: 'sdoh'
                  }
                ]
              }
            ],
            code: {
              coding: [
                {
                  system: 'http://snomed.info/sct',
                  code: '445281000124101'
                }
              ]
            },
            subject: {
              reference: 'Patient/123'
            },
            recordedDate: '2016-08-10T07:15:07-08:00',
            onsetDateTime: '2016-08-10T07:15:07-08:00',
            abatementDateTime: '2016-08-10T07:15:07-08:00'
          )
        end

        it 'passes if server suports all MS slices' do
          result = run_with_metadata([condition], condition_problems_health_concerns_metadata)
          expect(result).to be_empty
        end

        it 'fails if server does not support category:us-core slice' do
          condition.category.delete_if { |category| category.coding.first.code == 'problem-list-item' }

          result = run_with_metadata([condition], condition_problems_health_concerns_metadata)
          expect(result).to include('Condition.category:us-core')
        end
      end

      context 'with patternIdentifier slicing' do
        let(:practitioner_profile) { fixture('StructureDefinition-us-core-practitioner.json') }
        let(:practitioner) do
          FHIR::Practitioner.new(
            identifier: [
              {
                system: 'http://hl7.org/fhir/sid/us-npi',
                value: '9941339108'
              }
            ],
            name: [
              {
                family: 'Bone',
                given: ['Ronald'],
                prefix: ['Dr']
              }
            ],
            address: [
              {
                use: 'home',
                line: ['1003 Healthcare Drive'],
                city: 'Amherst',
                state: 'MA',
                postalCode: '01002'
              }
            ]
          )
        end

        it 'passes when NPI identifier slice present' do
          result = run(practitioner_profile, [practitioner], 'Practitioner')
          expect(result).to be_empty
        end

        it 'fails when no identifier present' do
          practitioner.identifier = []
          result = run(practitioner_profile, [practitioner], 'Practitioner')
          expect(result).to include('Practitioner.identifier:NPI')
        end

        it 'fails when identifier slice not present' do
          practitioner.identifier[0].system = 'http://example.com'
          result = run(practitioner_profile, [practitioner], 'Practitioner')
          expect(result).to include('Practitioner.identifier:NPI')
        end
      end

      context 'when MedicationRequest' do
        let(:medication_request_metadata) { metadata_fixture('medication_request_v501.yml') }
        let(:medication_request1) do
          FHIR::MedicationRequest.new(
            status: 'active',
            intent: 'order',
            category: [
              {
                coding: [
                  system: 'http://terminology.hl7.org/CodeSystem/medicationrequest-category',
                  code: 'outpatient'
                ]
              }
            ],
            reportedBoolean: false,
            medicationReference: {
              reference: 'Medication/m1'
            },
            subject: {
              reference: 'Patient/p1'
            },
            encounter: {
              reference: 'Encounter/e1'
            },
            authoredOn: '2021-08-04T00:00:00-04:00',
            requester: {
              reference: 'Practitioner/p2'
            },
            dosageInstruction: [
              {
                text: 'this is a dosage instruction'
              }
            ]
          )
        end

        it 'passes if server suports all MS slices' do
          result = run_with_metadata([medication_request1], medication_request_metadata)
          expect(result).to be_empty
        end
      end
    end
  end

  describe 'must support test for choices' do
    let(:condition_problems_health_concerns_metadata) do
      metadata_fixture('condition_problems_health_concerns_v501.yml')
    end
    let(:condition) do
      FHIR::Condition.new(
        extension: [
          {
            url: 'http://hl7.org/fhir/StructureDefinition/condition-assertedDate',
            valueDateTime: '2016-08-10'
          }
        ],
        clinicalStatus: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/condition-clinical',
              code: 'active'
            }
          ]
        },
        verificationStatus: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/condition-ver-status',
              code: 'confirmed'
            }
          ]
        },
        category: [
          {
            coding: [
              {
                system: 'http://terminology.hl7.org/CodeSystem/condition-category',
                code: 'problem-list-item'
              }
            ]
          },
          {
            coding: [
              {
                system: 'http://hl7.org/fhir/us/core/CodeSystem/us-core-tags',
                code: 'sdoh'
              }
            ]
          }
        ],
        code: {
          coding: [
            {
              system: 'http://snomed.info/sct',
              code: '445281000124101'
            }
          ]
        },
        subject: {
          reference: 'Patient/123'
        },
        recordedDate: '2016-08-10T07:15:07-08:00',
        onsetDateTime: '2016-08-10T07:15:07-08:00',
        abatementDateTime: '2016-08-10T07:15:07-08:00'
      )
    end

    it 'passes if server suports assertDate extension' do
      condition.onsetDateTime = nil

      result = run_with_metadata([condition], condition_problems_health_concerns_metadata)
      expect(result).to be_empty
    end

    it 'passes if server suports onsetDate' do
      condition.extension = []

      result = run_with_metadata([condition], condition_problems_health_concerns_metadata)
      expect(result).to be_empty
    end

    it 'fails if server suports none of assertDate extension and onsetDate' do
      condition.onsetDateTime = nil
      condition.extension = []

      result = run_with_metadata([condition], condition_problems_health_concerns_metadata)
      expect(result).to include('onsetDateTime')
      expect(result).to include('Condition.extension:assertedDate')
    end
  end

  describe 'must support test for Patient previous name choices' do
    let(:patient_profile) { fixture('StructureDefinition-us-core-patient.json') }

    context 'without custom metadata' do
      it 'passes if both use=old and period.end are provided' do
        result = run(patient_profile, [patient], 'Patient')
        expect(result).to be_empty
      end

      it 'passes if only use=old is presented' do
        patient.name[0].period = nil

        result = run(patient_profile, [patient], 'Patient')
        expect(result).to be_empty
      end

      it 'passes if only period.end is presented' do
        patient.name[0].use = nil

        result = run(patient_profile, [patient], 'Patient')
        expect(result).to be_empty
      end

      it 'passes if neither use=old nor period.end is presented' do
        # This one should pass since these are defined as MS by narrative only
        patient.name[0].use = nil
        patient.name[0].period = nil

        result = run(patient_profile, [patient], 'Patient')
        expect(result).to be_empty
      end
    end

    context 'with metadata block' do
      def add_previous_name_metadata(metadata)
        # See https://github.com/inferno-framework/us-core-test-kit/blob/b480ccf3e296b190dce5511d595de5e1a07e9c1a/lib/us_core_test_kit/generator/must_support_metadata_extractor_us_core_3.rb#L33
        metadata.must_supports[:elements] << {
          path: 'name.period.end',
          uscdi_only: true
        }
        metadata.must_supports[:elements] << {
          path: 'name.use',
          fixed_value: 'old',
          uscdi_only: true
        }

        metadata.must_supports[:choices] ||= []
        metadata.must_supports[:choices] << {
          paths: ['name.period.end', 'name.use'],
          uscdi_only: true
        }
      end

      it 'passes if both use=old and period.end are provided' do
        result = run(patient_profile, [patient], 'Patient') { |metadata| add_previous_name_metadata(metadata) }
        expect(result).to be_empty
      end

      it 'passes if only use=old is presented' do
        patient.name[0].period = nil

        result = run(patient_profile, [patient], 'Patient') { |metadata| add_previous_name_metadata(metadata) }
        expect(result).to be_empty
      end

      it 'passes if only period.end is presented' do
        patient.name[0].use = nil

        result = run(patient_profile, [patient], 'Patient') { |metadata| add_previous_name_metadata(metadata) }
        expect(result).to be_empty
      end

      it 'fails if neither use=old nor period.end is presented' do
        patient.name[0].use = nil
        patient.name[0].period = nil

        result = run(patient_profile, [patient], 'Patient') { |metadata| add_previous_name_metadata(metadata) }
        expect(result).to include('name.period.end')
        expect(result).to include('name.use:old')
      end
    end

    context 'with full provided metadata' do
      let(:patient_metadata) { metadata_fixture('patient_v311.yml') }

      it 'passes if both use=old and period.end are provided' do
        result = run_with_metadata([patient], patient_metadata)
        expect(result).to be_empty
      end

      it 'passes if only use=old is presented' do
        patient.name[0].period = nil

        result = run_with_metadata([patient], patient_metadata)
        expect(result).to be_empty
      end

      it 'passes if only period.end is presented' do
        patient.name[0].use = nil

        result = run_with_metadata([patient], patient_metadata)
        expect(result).to be_empty
      end

      it 'fails if neither use=old nor period.end is presented' do
        patient.name[0].use = nil
        patient.name[0].period = nil

        result = run_with_metadata([patient], patient_metadata)
        expect(result).to include('name.period.end')
        expect(result).to include('name.use:old')
      end
    end
  end

  describe 'must support tests for sub elements of slices' do
    let(:coverage_metadata) { metadata_fixture('coverage_v610.yml') }
    let(:group_class) do
      FHIR::Coverage::Class.new.tap do |loc_class|
        loc_class.type = FHIR::CodeableConcept.new.tap do |code_concept|
          code_concept.coding = [FHIR::Coding.new.tap do |coding|
            coding.system = 'http://terminology.hl7.org/CodeSystem/coverage-class'
            coding.code = 'group'
          end]
        end
        loc_class.value = 'group-class-value'
        loc_class.name = 'group-class-name'
      end
    end
    let(:plan_class) do
      FHIR::Coverage::Class.new.tap do |loc_class|
        loc_class.type = FHIR::CodeableConcept.new.tap do |code_concept|
          code_concept.coding = [FHIR::Coding.new.tap do |coding|
            coding.system = 'http://terminology.hl7.org/CodeSystem/coverage-class'
            coding.code = 'plan'
          end]
        end
        loc_class.value = 'plan-class-value'
        loc_class.name = 'plan-class-name'
      end
    end
    let(:coverage_with_two_classes) do
      FHIR::Coverage.new.tap do |cov|
        cov.status = 'active'
        cov.type = FHIR::CodeableConcept.new.tap do |code_concept|
          code_concept.coding = [FHIR::Coding.new.tap do |coding|
            coding.system = 'https://nahdo.org/sopt'
            coding.code = '3712'
            coding.display = 'PPO'
          end,
                                 FHIR::Coding.new.tap do |coding|
                                   coding.system = 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
                                   coding.code = 'PPO'
                                   coding.display = 'preferred provider organization policy'
                                 end],
                                code_concept.text = 'PPO'
        end,
                   cov.subscriberId = '888009335'
        cov.beneficiary = FHIR::Reference.new.tap do |ref|
          ref.reference = 'Patient/example'
        end
        cov.relationship = FHIR::CodeableConcept.new.tap do |code_concept|
          code_concept.coding = [FHIR::Coding.new.tap do |coding|
            coding.system = 'http://terminology.hl7.org/CodeSystem/subscriber-relationship'
            coding.code = 'self'
          end],
                                code_concept.text = 'Self'
        end,
                           cov.period = FHIR::Period.new.tap do |period|
                             period.start = '2020-01-01'
                           end
        cov.payor = [FHIR::Reference.new.tap do |ref|
          ref.reference = 'Organization/acme-payer'
          ref.display = 'Acme Health Plan'
        end],
                    cov.local_class = [group_class, plan_class]
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

    it 'passes if resources cover all must support sub elements of slices' do
      result = run_with_metadata([coverage_with_two_classes], coverage_metadata)
      expect(result).to be_empty
    end

    it 'fails if resources do not cover all must support sub elements of slices' do
      coverage_with_just_group = coverage_with_two_classes.dup
      coverage_with_just_group.local_class = [group_class]

      result = run_with_metadata([coverage_with_just_group], coverage_metadata)
      expect(result).to include('class:plan.value', 'class:plan.name', 'Coverage.class:plan')
    end

    it 'passes if resources cover all must support elements over multiple elements' do
      coverage_with_just_group = coverage_with_two_classes.clone
      coverage_with_just_group.local_class = [group_class]
      coverage_with_just_plan = coverage_with_two_classes.clone
      coverage_with_just_plan.local_class = [plan_class]

      result = run_with_metadata([coverage_with_two_classes], coverage_metadata)
      expect(result).to be_empty
    end
  end

  describe 'must support tests for primitive extension' do
    let(:qr_metadata) { metadata_fixture('questionnaire_response_v610.yml') }
    let(:qr) { FHIR.from_contents(File.read('spec/fixtures/QuestionnaireResponse.json')) }

    it 'passes if server suports all MS slices' do
      result = run_with_metadata([qr], qr_metadata)
      expect(result).to be_empty
    end

    it 'fails if both MS extensions in a primitive are not provided' do
      qr.source_hash['_questionnaire']['extension'][0]['url'] = 'http://example.com/extension'
      qr.source_hash['_questionnaire']['extension'][1]['url'] = 'http://example.com/extension'
      new_qr = FHIR::QuestionnaireResponse.new(qr.source_hash)

      result = run_with_metadata([new_qr], qr_metadata)
      expect(result).to include('QuestionnaireResponse.questionnaire.extension:questionnaireDisplay')
      expect(result).to include('QuestionnaireResponse.questionnaire.extension:url')
    end

    it 'fails if both MS extensions and MS element in a primitive are not provided' do
      qr.source_hash['_questionnaire']['extension'][0]['url'] = 'http://example.com/extension'
      qr.source_hash['_questionnaire']['extension'][1]['url'] = 'http://example.com/extension'
      new_qr = FHIR::QuestionnaireResponse.new(qr.source_hash)
      new_qr.questionnaire = nil

      result = run_with_metadata([new_qr], qr_metadata)
      expect(result).to include('QuestionnaireResponse.questionnaire.extension:questionnaireDisplay')
      expect(result).to include('QuestionnaireResponse.questionnaire.extension:url')
      expect(result).to include('questionnaire')
    end

    it 'fails if one of MS extensions in a primitive is not provided' do
      qr.source_hash['_questionnaire']['extension'][0]['url'] = 'http://example.com/extension'
      new_qr = FHIR::QuestionnaireResponse.new(qr.source_hash)

      result = run_with_metadata([new_qr], qr_metadata)
      expect(result).to include('QuestionnaireResponse.questionnaire.extension:questionnaireDisplay')
      expect(result).to_not include('QuestionnaireResponse.questionnaire.extension:url')
      expect(result).to_not include('questionnaire')
    end

    it 'fails if MS primitive value is missing' do
      new_hash = qr.source_hash.except('status')
      new_qr = FHIR::QuestionnaireResponse.new(new_hash)

      result = run_with_metadata([new_qr], qr_metadata)
      expect(result).to include('status')
    end

    it 'fails if regular extension is provided for MS primitive without MS extension' do
      new_hash = qr.source_hash.except('status')
      new_hash['_status'] = {
        'extension' => [
          {
            'url' => 'http://example.com/extension',
            'valueString' => 'value'
          }
        ]
      }

      new_qr = FHIR::QuestionnaireResponse.new(new_hash)

      result = run_with_metadata([new_qr], qr_metadata)
      expect(result).to include('status')
    end

    it 'fails if MS element (not primitive) is missing' do
      qr.subject = nil

      result = run_with_metadata([qr], qr_metadata)
      expect(result).to include('subject')
    end

    it 'fails if regular extension is provided for MS element (not primitive)' do
      qr.subject = FHIR::Reference.new(
        extension: [
          {
            url: 'http://example.com/extension',
            valueString: 'value'
          }
        ]
      )

      result = run_with_metadata([qr], qr_metadata)
      expect(result).to include('subject')
    end
  end
end
