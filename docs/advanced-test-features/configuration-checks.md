---
title: Configuration Checks
nav_order: 5
parent: Advanced Features
---
# Configuration Checks
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Overview
Test Suites can have a set of checks they perform on startup to ensure that
their environment is correctly configured. These checks are performed the first
time a session is created for the suite. The checks can be refreshed [using the
JSON API](/inferno-core/api-docs/#/Test
Suite/put_test_suites__test_suite_id__check_configuration).

### Defining Configuration Checks
The `check_configuration` method defines a check to be performed. It takes a
block which returns an Array of message hashes.

```ruby
class MySuite < Inferno::TestSuite
  check_configuration do
    messages = []
    
    if validator_is_correct_version?
      messages << { type: 'info', message: 'Correct validator version' }
    else
      messages << { type: 'error', message: 'Incorrect validator version' }
    end
    
    if service_xyz_is_available?
      messages << { type: 'info', message: 'Service XYZ is available' }
    else
      messages << { type: 'error', message: 'Service XYZ is unavailable' }
    end
    
    messages
  end
end
```
