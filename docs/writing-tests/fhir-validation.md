---
title: FHIR Validation
nav_order: 6
parent: Writing Tests
---
# FHIR Resource Validation
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Overview
[FHIR resource validation](https://www.hl7.org/fhir/validation.html) is
performed by the [FHIR Validator Wrapper
service](https://github.com/inferno-framework/fhir-validator-wrapper). When
creating a test kit based on the template:

* Place the `.tgz` IG packages for any profiles you need to validate against in
  `lib/YOUR_TEST_KIT_NAME/igs`.
* Make sure that the volume path in `docker-compose.background.yml` points to
  the above directory.
* Restart the validator service after adding/changing any IGs.

### Defining Validators
The test kit template defines a validator in the suite, and it is not necessary
to alter it unless you need multiple validators or want to add extra validator
behaviors. Validators are defined with `validator`:

```ruby
validator :optional_validator_name do
  # Read the validator URL from an environment variable
  url ENV.fetch('VALIDATOR_URL')
end
```

[`validator` in the API
docs](/inferno-core/docs/Inferno/DSL/FHIRValidation/ClassMethods.html#validator-instance_method)

### Validating FHIR Resources
The `resource_is_valid?` method will validate a FHIR resource and add any
validation messages to the runnable.

```ruby
test do
  fhir_read :patient, '123'
  
  # Validate the resource from the last request
  if resource_is_valid?
  end
  
  # Validate some other resource
  if resource_is_valid?(resource: some_other_resource)
  end
  
  # Validate against a particular profile
  if resource_is_valid?(profile_url: 'http://example.com/fhir_profile_url')
  end
  
  # Validate using a particular named validator
  if resource_is_valid?(validator: :my_customized_validator)
  end
end
```

[`resource_is_valid?` in the API
docs](/inferno-core/docs/Inferno/DSL/FHIRValidation.html#resource_is_valid%3F-instance_method)

`assert_valid_resource` will validate the resource, add any validation messages
to the runnable, and fail the test if the resource is invalid.

```ruby
test do
  fhir_read :patient, '123'
  
  # Use the resource from the last request
  assert_valid_resource
  
  # Validate some other resource
  assert_valid_resource(resource: some_other_resource)
  
  # Validate against a particular profile
  assert_valid_resource(profile_url: 'http://example.com/fhir_profile_url')
  
  # Validate using a particular named validator
  assert_valid_resource(validator: :my_customized_validator)
end
```

[`assert_valid_resource` in the API
docs](/inferno-core/docs/Inferno/DSL/Assertions.html#assert_valid_resource-instance_method)

### Filtering Validation Messages
If you need to ignore certain validation messages in your test kit, this can be
done using the `exclude_message` method in the validator definition.

```ruby
validator do
  url ENV.fetch('VALIDATOR_URL')
  # Messages will be excluded if the block evaluates to a truthy value
  exclude_message do |message|
    message.type == 'info' ||
      message.message.include?('message to ignore') ||
      message.message.match?(/regex_filter/)
  end
end
```

### Performing Additional Validation
Additional resource validation can be done using the
`perform_additional_validation` method in the validator definition. This method
can be used multiple times in a single validator definition to add multiple
additional validation steps. To add additional validation messages, the block in
this method must return a single Hash with a `type` and `message`, or an Array
of Hashes with those keys. If the block returns `nil`, no new messages are
added. The resource is considered invalid if any messages with a `type` of
`error` are present.

```ruby
validator do
  url ENV.fetch('VALIDATOR_URL')
  perform_additional_validation do |resource, profile_url|
    if something_is_wrong
      { type: 'error', message: 'something is wrong'}
    end
  end
end
```
