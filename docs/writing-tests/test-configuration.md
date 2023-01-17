---
title: Suite/Group/Test Configuration
nav_order: 6
parent: Writing Tests
---
# Suite/Group/Test Configuration
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Configuration and Options
Inferno provides two mechanisms for altering test behavior.

### Configuration

* Defined at the test, group, or suite level.
* Evaluated at boot time.
* Can be used within a test's `run` block to modify test behavior.
* Can modify inputs/outputs/requests to avoid naming collisions.
* Can modify input properties such as whether an input is required or locked.
* Can define custom boot-time options for tests.

### Suite Options

* Only defined at the suite level.
* Evaluated at test session creation time. When starting a test session, the
  user will be prompted to make a choice for each option.
* Can modify which tests/groups appear in the UI and are executed.
* Can be used within a test's `run** block to modify test behavior.

## Configuration

TODO

## Suite Options

Suite options provide a way for users to select high level options that alter
which tests/groups are executed during a session. For example, a test suite may
support testing against different versions of an implementation guide, and based
on which version the user selects when starting their session, the tests for the
other versions can be hidden.

### Defining Suite Options

Suite options must be defined within a test suite and have the following
properties:
* `identifier` - a Symbol which is used to identify this option
* `title` - the title which is displayed to users
* `list_options` - the possible values for this option. Each list option
  contains a `label` which is displayed to users, and a `value` which is the
  actual value stored when the user selects this option.

```ruby
class MyTestSuite < Inferno::TestSuite
  suite_option :smart_app_launch_version,
                title: 'SMART App Launch Version',
                list_options: [
                  {
                    label: 'SMART App Launch 1.0.0',
                    value: 'smart_app_launch_1'
                  },
                  {
                    label: 'SMART App Launch 2.0.0',
                    value: 'smart_app_launch_2'
                  }
                ]
end
```

### Hiding Tests Based on Suite Options

Tests/groups can be hidden from the user and prevented from executing based on
the selected suite options. In the following example (using the suite option
definition from above), the user will only see the SMART App Launch group for
the version which they selected when starting their session.

```ruby
class MyTestSuite < Inferno::TestSuite
  # suite_option :smart_app_launch_version,
  # ...
  
  # Suite option requirements can be defined inline
  group from: :smart_app_launch_v1,
        required_suite_options: {
          smart_app_launch_version: 'smart_app_launch_1'
        }
        
  # Suite option requirements can be defined within a test/group definition
  group from: :smart_app_launch_v2 do
    required_suite_options smart_app_launch_version: 'smart_app_launch_2'
  end
end
```

### Altering Test Behavior Based on Suite Options

Test behavior can be modified by inspecting the value of an option inside of the
`run` block.

```ruby
class MyTest < Inferno::Test
  run do
    if suite_options[:smart_app_launch_version] == 'smart_app_launch_1'
      # Perform SMART App Launch v1 behavior
    elsif suite_options[:smart_app_launch_version] == 'smart_app_launch_2'
      # Perform SMART App Launch v2 behavior
    end
  end
end
```
