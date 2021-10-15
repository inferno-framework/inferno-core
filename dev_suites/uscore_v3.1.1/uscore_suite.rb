Dir[File.join(__dir__, 'groups', '**', '*.rb')].each { |file| require file }
require_relative '../dev_smart/discovery_group'
require_relative '../dev_smart/standalone_launch_group'

module USCore # rubocop:disable Naming/ClassAndModuleCamelCase
  class USCore_Suite < Inferno::TestSuite
    title 'US Core v3.1.1 Suite'
    id 'ONCProgram'

    # Ideas:
    # * Suite metadata (name, associated ig, version, etc etc)
    # * Be able to define new sequences that map inputs, force certain parameters, etc
    # * Allow suites / groups to have inputs (for suites inputs, have it be like what 'url'
    #   is for legacy inferno)
    # * Different types of gruops
    # * Default group?
    # * Sequences in groups should be uniquely identified, basically what inferno 'test cases'
    #   are.  Group id + sequence id.

    # group title: 'the first group',
    #   id: :first_group,
    #   link: 'http://example.com',
    #   description: %( This is the description for the first test! ) do

    # This is a little too simplistic, because we want groups to be able to
    # restrict params, map params, etc

    validator do
      url ENV.fetch('VALIDATOR_URL')
      exclude_message { |message| message.type == 'info' }
    end
    group do
      title 'Standalone Patient App - Full Patient Access'
      group from: :smart_discovery
      group from: :smart_standalone_launch
    end

    group do
      title 'Single Patient API'

      input :url
      input :standalone_patient_id, title: 'Patient ID'
      input :standalone_access_token, title: 'Bearer Token'

      fhir_client :single_patient_client do
        url :url
        bearer_token :standalone_access_token
      end

      group from: 'USCore::USCoreCapabilityStatement'
      group from: 'USCore::AllergyIntoleranceSequence'
    end
  end
end
