
require_relative 'tls_test'

module USCore
  class USCoreCapabilityStatement < Inferno::TestGroup
    title 'Capability Statement'
    description <<~DESCRIPTION
      # Background
      The #{title} Sequence tests a FHIR server's ability to formally describe
      features supported by the API by using the [Capability
      Statement](https://www.hl7.org/fhir/capabilitystatement.html) resource.
      The features described in the Capability Statement must be consistent
      with the required capabilities of a US Core server. The Capability
      Statement must also advertise the location of the required SMART on FHIR
      endpoints that enable authenticated access to the FHIR server resources.

      The Capability Statement resource allows clients to determine which
      resources are supported by a FHIR Server. Not all servers are expected
      to implement all possible queries and data elements described in the US
      Core API. For example, the US Core Implementation Guide requires that
      the Patient resource and only one additional resource profile from the
      US Core Profiles.


      # Test Methodology

      This test suite accesses the server endpoint at `/metadata` using a
      `GET` request. It parses the Capability Statement and verifies that:

      * The endpoint is secured by an appropriate cryptographic protocol
      * The resource matches the expected FHIR version defined by the tests
      * The resource is a valid FHIR resource
      * The server claims support for JSON encoding of resources
      * The server claims support for the Patient resource and one other
        resource

      It collects the following information that is saved in the testing
      session for use by later tests:

      * List of resources supported
      * List of queries parameters supported
    DESCRIPTION

    input :url
    output :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

    test from: :tls_test
    

    test do
      title 'FHIR server supports the conformance interaction'
      description <<~DESCRIPTION
        The conformance 'whole system' interaction provides a method to get
        the conformance statement for the FHIR server. This test checks that
        the server responds to a `GET` request at the following endpoint:

        ```
        GET [base]/metadata
        ```

        This test checks the following SHALL requirement:

        > Applications SHALL return a resource that describes the
          functionality of the server end-point.

        [http://hl7.org/fhir/R4/http.html#capabilities](http://hl7.org/fhir/R4/http.html#capabilities)

        It does this by checking that the server responds with an HTTP OK
        200 status code and that the body of the response contains a valid
        [CapabilityStatement
        resource](http://hl7.org/fhir/R4/capabilitystatement.html). This
        test does not inspect the content of the Conformance resource to see
        if it contains the required information. It only checks to see if
        the RESTful interaction is supported and returns a valid
        CapabilityStatement resource.
      DESCRIPTION
      # link 'http://hl7.org/fhir/DSTU2/http.html#conformance'

      run do
        client = fhir_client(:single_patient_client)
        client.set_no_auth
        conformance = client.conformance_statement
        assert_response_status(200, client.reply)

        # output conformance: conformance

        # fhir_version?
        # assert_valid_conformance(conformance)

        # how to handle server capabilities?
      end
    end

    test do
      title 'FHIR version of the server matches the FHIR version expected by tests'
      description <<~DESCRIPTION
        Checks that the FHIR version of the server matches the FHIR version
        expected by the tests. This test will inspect the
        CapabilityStatement returned by the server to verify the FHIR
        version of the server.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/directory.cfml'

      run {}
    end

    test do
      title 'FHIR server capability states JSON support'
      description <<~DESCRIPTION
        FHIR provides multiple [representation
        formats](https://www.hl7.org/fhir/formats.html) for resources,
        including JSON and XML. US Core profiles require servers to use the
        [JSON representation](https://www.hl7.org/fhir/json.html):

        [```The US Core Server **SHALL** Support json source formats for all
        US Core
        interactions.```](http://hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior)

        The FHIR capability interaction require servers to describe which
        formats are available for clients to use. The server must explicitly
        state that JSON is supported. This is located in the [format
        element](https://www.hl7.org/fhir/capabilitystatement-definitions.html#CapabilityStatement.format)
        of the CapabilityStatement Resource.

        This test checks that one of the following values are located in the
        format field.

        * json
        * application/json
        * application/fhir+json
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'

      run {}
    end

    test do
      title 'Capability Statement lists support for required US Core Profiles'
      description <<~DESCRIPTION
        The US Core Implementation Guide states:

        ```
        The US Core Server SHALL:
        1. Support the US Core Patient resource profile.
        2. Support at least one additional resource profile from the list of
          US Core Profiles.
        ```
      DESCRIPTION
      # link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'

      run {}
    end
  end
end
