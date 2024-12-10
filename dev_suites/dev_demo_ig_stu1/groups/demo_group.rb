# To run during development
# Inferno::TestRunner.new.run({url: 'http://hapi.fhir.org/baseR4', patient_id: 1215072}, DemoGroup)

module DemoIG_STU1 # rubocop:disable Naming/ClassAndModuleCamelCase
  class DemoGroup < Inferno::TestGroup
    title 'Demo Group'

    description %(
    # This is a markdown header
    **Inferno** [github](https://github.com/inferno-framework/inferno-core)

    Below is a markdown table
    | Column 1 | Column 2 | Column 3 |
    | :--- | :---: | ---: |
    | Entry 1 | Entry 2 | Entry 3|
    | Entry 4 | Entry 5 | Entry 6 |

    This is a dummy canonical link http://hl7.org/fhir/ValueSet/my-valueset|0.8 that should not be
    interpreted as a table

    > This is a blockquote.
    >
    > Blockquotes are useful for quoting standards or other references.

    )

    # Inputs and outputs

    # Rename 'requires' and 'provides' to 'input' and 'output' to be more clear
    # about the purpose of these values.  We discussed including type hints here,
    # while also allowing type hints at a higher level.

    input :url, title: 'URL', description: 'Insert url of FHIR server', default: 'https://inferno.healthit.gov/reference-server/r4'
    input :patient_id, title: 'Patient ID', default: '85'
    input :bearer_token, optional: true, default: 'SAMPLE_TOKEN'

    output :observation_id,
           :encounter_id,
           :bearer_token

    # Client Setup

    # Have a specific part at the top that initializes one or more clients that
    # point to specific endpoints. Then use fhir_read, or http_get notation (not
    # needing to pass in a URL) within tests itself. Using @client is likely
    # confusing to non-ruby users (why the @?), and things like a FHIR client is
    # so fundamental to the test library that it should just be part of the DSL.

    fhir_client :this_client_name do # name optional
      url :url # if symbol just use a input?
      bearer_token :bearer_token

      # format: format # if you want to be able to specify in input
      # format: 'xml' # if you want to override default 'json'
      # format: 'auto' # perhaps at beginning of every test query /metadata?
    end

    http_client do
      url 'http://example.com'
    end

    test 'successful tests' do
      run { assert 1 + 1 == 2 }
    end

    test 'warning message/optional test' do
      optional
      run do
        warning %(
          # blah
          *boo*
        )
      end
    end

    test 'error test' do
      run { assert 1 / 0 }
    end

    test 'input use example' do
      # Currently auto-assigning inputs to string variables in the method

      run { info "Received the following 'url' variable: '#{url}''" }
    end

    test 'output use example' do
      run do
        # option 1: explicitly call output method
        # Note: this is the currently preferred method
        observation_id_local = 5
        output observation_id: observation_id_local

        # option 2: explicitely set output using output.name = 'xyz' form.
        # Note: not implemented
        # output.observation_id = observation_id_local

        # option 3: set using the @ shortcut
        # we may want to remove this though!
        # NOTE: This no longer works
        # @encounter_id = 10

        # demonstrate that if you set the observation_id you must run the 'output' method on it
        # immediately or risk an exception causing it to not be returned
        observation_id = 5000
        assert false
        output observation_id: # will not be reached
      end
    end

    test 'uses output example' do
      input :observation_id
      run { info "Received the following 'observation_id' variable: '#{observation_id}'" }
    end

    test 'client use examples test' do
      run do
        fhir_read :patient, patient_id, client: :this_client_name
        # fhir_read :patient, '5', client: :this_client_name, request_name: :something_else
        # fhir_read :care_plan
        # fhir_read 'patient'

        info "Performed #{request.request[:verb].to_s.upcase}, " \
             "received HTTP #{response[:status]} with patient id: #{resource&.id}"

        assert_response_status(200)
        assert_response_status([200, 201])
        # TODO: assert_response_status(200, request_name: :something_else)

        assert_resource_type('Patient')
        assert_resource_type(:Patient)
        assert_resource_type(FHIR::Patient)
        # also assert_resource_type('diagnostic_report')
        # also assert_resource_type(:diagnostic_report)
        # TODO: assert_resource_type('Patient', request_name: :something_else)

        # NOTE: we may consider having some built-in auto validation around
        # responses (you can't send a 999 status code, for example).
        # assert_valid response
        assert_valid_resource

        fhir_search :observation,
                    client: :this_client_name,
                    params: { patient: resource.id }
        #   compartment: { id: '123', resource_type: patient },
        #   format: :json,
        #   additional_headers: { header_one: blah }
        # fhir_search params: {param1: this, param2: that}, verb: post
        assert_response_status(200)
        assert_resource_type('Bundle')

        # fhir_create FHIR::Patient.new({name: blah})
      end
    end

    test 'warning block test' do
      run do
        fhir_read :patient, patient_id, client: :this_client_name

        warning { assert_response_status(201) }
        warning { assert_resource_type('Observation') }
      end
    end

    test 'skip test' do
      run do
        skip %(
          This test is being skipped.
          1. This
          2. Is
          3. Markdown
        )
        assert false
      end
    end

    test 'omit test' do
      run do
        omit 'This test is being omitted'
        assert false
      end
    end

    test 'pass test' do
      run do
        pass 'This test passes because blah'
        assert false
      end
    end

    test 'skip_if test' do
      run do
        skip_if 1 < 2, 'This test is being skipped'
        assert false
      end
    end

    test 'omit_if test' do
      run do
        omit_if 1 < 2, 'This test is being omitted'
        assert false
      end
    end

    test 'pass_if test' do
      run do
        pass_if 1 < 2, 'This test passes because blah'
        assert false
      end
    end

    test 'make named fhir request' do
      makes_request :fhir_request

      run do
        fhir_read :patient, patient_id, client: :this_client_name, name: :fhir_request

        assert_response_status(200)
      end
    end

    test 'use named fhir request' do
      uses_request :fhir_request

      run do
        assert_response_status(200)

        fhir_request = named_request(:fhir_request)

        assert request == fhir_request, 'Default request is not the same as the named request'
      end
    end

    test 'make named http request' do
      makes_request :http_request

      run do
        get(name: :http_request)

        assert_response_status(200)
      end
    end

    test 'use named http request' do
      uses_request :http_request

      run do
        assert_response_status(200)

        http_request = named_request(:http_request)

        assert request == http_request, 'Default request is not the same as the named request'
      end
    end

    test 'textarea input' do
      input :textarea,
            title: 'Textarea Input Example',
            type: 'textarea',
            description: 'Insert something like a patient resource json here',
            optional: true

      run { info "Received the following 'textarea' variable: '#{textarea}''" }
    end

    test 'radio group input' do
      input :radio,
            title: 'Radio Group Input Example',
            type: 'radio',
            description: 'Radio description',
            optional: false,
            options: {
              list_options: [
                {
                  label: 'Label 1',
                  value: 'value1'
                }, {
                  label: 'Label 2',
                  value: 'value2'
                }
              ]
            }

      run { info "Received the following 'radio' variable: '#{radio}'" }
    end

    test 'checkbox group input' do
      input :checkbox_group,
            title: 'Checkbox Group Input Example',
            type: 'checkbox',
            description: 'Checkbox description',
            default: ['value2'],
            optional: false,
            options: {
              list_options: [
                {
                  label: 'Label 1',
                  value: 'value1'
                }, {
                  label: 'Label 2',
                  value: 'value2'
                }
              ]
            }

      run { info "Received the following 'checkbox' variable: '#{checkbox_group}'" }
    end

    test 'locked checkbox group input' do
      input :locked_checkbox_group,
            title: 'Locked Checkbox Group Input Example',
            type: 'checkbox',
            description: 'Checkbox description',
            default: ['value2'],
            optional: false,
            options: {
              list_options: [
                {
                  label: 'Label 1',
                  value: 'value1'
                }, {
                  label: 'Label 2',
                  value: 'value2',
                  locked: true
                }
              ]
            }

      run { info "Received the following 'checkbox' variable: '#{locked_checkbox_group}'" }
    end

    test 'single checkbox input' do
      input :single_checkbox,
            title: 'Single Checkbox Input Example',
            type: 'checkbox',
            description: 'Checkbox description',
            default: ['true'],
            optional: false

      run { info "Received the following 'checkbox' variable: '#{single_checkbox}'" }
    end

    test 'locked single checkbox input' do
      input :locked_single_checkbox,
            title: 'Locked Single Checkbox Input Example',
            type: 'checkbox',
            description: 'Checkbox description',
            default: ['true'],
            optional: false,
            locked: true

      run { info "Received the following 'checkbox' variable: '#{locked_single_checkbox}'" }
    end

    test 'OAuth Credentials group input' do
      input :credentials,
            title: 'OAuth Credentials Group Input Example',
            type: 'oauth_credentials',
            description: 'OAuth Credentials description',
            optional: true

      run { info "Received the following 'credentials' variable: '#{credentials}'" }
    end

    test 'locked input' do
      input :patient_name, title: 'Patient Name', description: 'Example of locked, empty input field',
                           locked: true, optional: true
      input :url_locked, title: 'URL', description: 'Example of locked, filled input field',
                         default: 'https://inferno.healthit.gov/reference-server/r4', locked: true
      input :textarea_locked, title: 'Textarea Input', description: 'Example of locked, filled input field',
                              type: 'textarea', default: 'Hello Inferno demo user.', locked: true

      input :patient_id, locked: true

      run { info 'Submitted without changes to patient name, url, or textarea input' }
    end

    test 'write to scratch' do
      run { scratch[:abc] = 'xyz' }
    end

    test 'read from scratch' do
      run { assert scratch[:abc] == 'xyz' }
    end

    test 'tag a request' do
      run do
        fhir_read :patient, patient_id, client: :this_client_name, tags: ['example_tag_1', 'example_tag_2']
      end
    end

    test 'load a tagged request' do
      run do
        tagged_requests = load_tagged_requests('example_tag_1', 'example_tag_2')

        assert tagged_requests.length == 1, 'Incorrect number of requests loaded'
        assert request.id == tagged_requests.first.id, 'Incorrect request loaded'
      end
    end
  end
end
