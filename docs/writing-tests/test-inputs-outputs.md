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

## Defining Outputs
