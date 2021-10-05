---
title: Test Inputs/Outputs
nav_order: 3
parent: Writing Tests
---
# Test Inputs/Outputs
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Overview
Inputs and outputs provide a structured way to pass information into and out of
tests. When a user initiates a test run, a modal is displayed allowing them to
provide input values. When multiple tests are being run together, the user is
not prompted for inputs which can be populated by the output of a previous test
in the run. Currently, all inputs and outputs are stored as strings.

## Defining Inputs
The `input` method defines an input. `input` can take several arguments, but
only the identifier is required:
- `identifier` - (**required**) a name for this input. The input value is
  available in the run block using this name.
- `title:` -  a title which is displayed in the UI.
- `description:` - a description which is displayed in the UI.
- `type:` - controls the type of html input element used in the UI. Currently
  two possible values:
  - `'text'` - (**default**) a regular input field.
  - `'textarea'` - for a text area input field.
- `default:` - default value for the input.
- `optional:` - (**default: false**) whether the input is optional.

```ruby
test do
  input :url,
        title: 'FHIR Server Url',
        description: 'The base url for the FHIR server'
        
  run do
    # The input's identifier is :url, so its value is available via `url`
    assert url.start_with?('https'), 'The server must support https'
  end
end
```
[`input` in the API docs](/docs/Inferno/DSL/Runnable.html#input-instance_method)

### Defining Multiple Inputs
It is possible to define multiple inputs in a single `input` call, but not with
any of the additional properties listed above.

```ruby
test do
  input :input1, :input2, :input3, :input4
  ...
end
```

## Defining Outputs
The `output` method defines an output. It is used in a test's definition block
to define which outputs a test uses, and within a test's `run` block to assign a
value to an output. Multiple outputs can be defined/assigned at once.

```ruby
test do
  output :value1
  output :value2, :value3
  
  run do
    output value1: 'ABC'
    output value2: 'DEF',
           value3: 'GHI'
  end
end

test do
  # These inputs will automatically get their values from the previous test's
  # outputs.
  input :value1, :value2, :value3
  ...
end
```
[`output` for defining outputs in the API docs](/docs/Inferno/Entities/Test.html#output-class_method)

[`output` for assigning values to outputs in the API docs](/docs/Inferno/Entities/Test.html#output-instance_method)

## Handling Complex Objects
Since inputs and outputs are all stored as strings, special handling is needed
if you want to use them to pass complex objects between tests. This can
generally be handled using JSON serialization. Ruby hashes and arrays, as well
as FHIR model classes support the `to_json` method turn the object into a JSON
string.

```ruby
test do
  output :complex_object_json
  
  run do
    ...
    output complex_object_json: hash_or_array_or_fhir_resource.to_json
  end
end

test do
  input :complex_object_json
  
  run do
    assert_valid_json(complex_object_json) # For safety

    complex_object = JSON.parse(complex_object_json)
    ...
  end
end
```

## Behind the Scenes
Inputs and outputs work as a single key-value store scoped to a test session.
The main differences between them are that an input's value can not be changed
during a test, and inputs support additional metadata for display in the UI
(title, description, etc.). Since inputs and outputs form a single key-value
store, a value will be overwritten if multiple tests write to the same output.
However, each test result stores the input/output values that were present for
that particular test.
