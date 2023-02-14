---
title: Scratch
nav_order: 4
parent: Advanced Features
---
# Scratch
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Overview
Scratch provides an alternative to inputs and outputs for passing information
between tests. Inputs and outputs should be preferred over scratch when
possible.

| Inputs/Outputs | Scratch |
| --- | --- |
| Stored in the database | Stored in memory |
| Strings | Any data type |
| Persist through an entire test session | Lifetime limited to a single test run |
| Input values only change if they are a test output | Any test can change scratch |

The major advantage of scratch is that its contents are stored in memory. Inputs
are loaded from the database at the start of each test. If tests require a large
number of complex objects, scratch provides a way to avoid repeatedly loading,
deserializing, and instantiating them. The major limitation of scratch is that
it only persists through a single test run (i.e., a single click of the _Run
Tests_ button).

## Example
`scratch` is just a plain Hash which is passed to each test.

```ruby
class MyGroup < Inferno::TestGroup
  # Since scratch is lost at the end of a test run, by making this group run
  # together, that ensures that the tests run together and the scratch will
  # remain present.
  run_as_group
  
  test do
    run do
      # retrieve a large number of FHIR resources
      # ...
      
      scratch[:observations] = a_large_number_of_fhir_observations
      scratch[:conditions] =  a_large_number_of_fhir_conditions
    end
  end
  
  test do
    run do
      perform_some_operation_on(scratch[:observations])
    end
  end
  
  test do
    run do
      perform_some_operation_on(scratch[:conditions])
    end
  end
end
```
