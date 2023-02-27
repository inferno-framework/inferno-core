---
title: Assertions and Results
nav_order: 5
parent: Writing Tests
---
# Assertions and Results
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Assertions
Assertions are used in Inferno to check the behavior under test. When an
assertion fails, execution of that test ends, and it gets a failing result. The
most basic form of an assertion is the `assert` method, which takes two
arguments:
- The first argument determines whether the assertion passes or fails. It will
  pass if the value is truthy (anything other than `false` or `nil`), and fail
  if the value is falsey (`false` or `nil`).
- The second value is the message which will be displayed if the assertion
  fails.
 
```ruby
test do
  run do
    assert 1 > 0, 'This assertion will never fail'
    assert 1 < 0, '1 is not less than 0'
  end
end
```
Inferno also implements more specific assertions to handle common cases, such as:
- Verifying the http status code of a response.
- Verifying that a string is valid JSON.
- Validating a FHIR Resource.

Check out the [assertions API
documentation](/inferno-core/docs/Inferno/DSL/Assertions.html) for detailed
information on all available assertions.

### Assertion Examples

```ruby
test do
  first_request = fhir_read(:patient, '123')
  second_request = fhir_read(:patient, '456')

  # These assertions are all made against the second request
  assert_response_status(200)
  assert_response_content_type('application/fhir+json')
  assert_valid_json(request.response_body)
  assert_resource_type(:patient)
  assert_valid_resource

  # These assertions are all made against the first request
  assert_response_status(200, request: first_request)
  assert_response_content_type('application/fhir+json', request: first_request)
  assert_valid_json(first_request.response_body)
  assert_resource_type(:patient, resource: first_request.resource)
  assert_valid_resource(resource: first_request.resource)

  # Validate against a specific profile
  assert_valid_resource(profile_url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient')

  fhir_search(:medication_request, params: { patient: '123', _include: 'MedicationRequest:medication'_ })

  # Bundle entry validation
  # Validate all entries from the most recent request
  assert_valid_bundle_entries
  # Only validate MedicationRequest bundle entries
  assert_valid_bundle_entries(resource_types: 'MedicationRequest')
  # Only validate MedicationRequest and Medication bundle entries
  assert_valid_bundle_entries(resource_types: ['MedicationRequest', 'Medication'])
  # Only validate MedicationRequest and Medication bundle entries. Validate
  # MedicationRequest resources against the given profile, and Medication
  # resources against the base FHIR Medication resource.
  assert_valid_bundle_entries(
    resource_types: {
      'MedicationRequest': 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest',
      'Medication': nil
    }
  )
end
```

## Results
Tests can have the following results in Inferno:
- `pass` - Inferno was able to verify correct behavior.
- `fail` - Inferno was able to verify incorrect behavior.
- `skip` - Inferno was unable to verify correct or incorrect behavior. For
  instance, a test may need to validate a Condition resource, but none are
  available on the server. Inferno was not able to validate the resource, but
  the server is also not demonstrating incorrect behavior. A `skip` prevents a
  test session from passing because some behavior could not be verified.
- `omit` - Inferno does not need to verify behavior. For example, an
  Implementation Guide may say that if a server does not do A, then it must do
  B. Inferno has verified that the server does A, so it does not make sense to
  verify B. An `omit` does not prevent a test session from passing because it
  indicates behavior that does not need to be verified.
- `error` - Something unexpected happened and caused an internal server error.
  This indicates a problem in a test kit or in Inferno itself. You should
  contact the test kit author or the Inferno team.
- `wait` - A test is waiting to receive an incoming request, and will resume
  once it is received (see [Waiting for an Incoming
  Request](/inferno-core/advanced-test-features/waiting-for-requests.html)).
- `cancel` (not yet implemented)

### Assigning specific results
Inferno provides methods to assign some specific results to a test:
- `pass/pass_if` - These can be used to end test execution early.
- `skip/skip_if`
- `omit/omit_if`

The `*_if` methods take the same kind of arguments as `assert`, a value whose
truthiness will be evaluated, and a message to be displayed. The other methods
just take a message. For more information, view the [results API
documentation](/inferno-core/docs/Inferno/DSL/Results.html).

```ruby
test do
  run do
    omit_if test_should_be_omitted, 'This test is being omitted because...'
    skip_if test_should_be_skipped, 'This test is being skipped because...'
    pass_if test_should_pass
    
    skip 'This test is being skipped'
  end
end
```

## Adding Messages to Results
Test results can have error, warning, and info messages associated with them.
Error messages are typically generated by failing assertions. You can use the
`warning` and `info` messages to add those message types to a result, or to turn
a failed assertion message into a warning or info message. Info and warning
messages are dispayed in the UI, but do not affect the test result.

```ruby
test do
  run do
    info 'This info message will be added to the result'
    info do
      assert false, %(
        This assert is inside an `info` block, so it will not halt test execution
        if it fails, and this will be an info message rather than an error
        message.
      )
    end
    
    warning 'This warning message will be added to the result'
    warning do
      assert false, %(
        This assert is inside a `warning` block, so it will not halt test
        execution if it fails, and this will be a warning message rather than an
        error message.
      )
    end
  end
end
```
[`info` in the API
docs](/inferno-core/docs/Inferno/Entities/Test.html#info-instance_method)

[`warning` in the API
docs](/inferno-core/docs/Inferno/Entities/Test.html#warning-instance_method)
