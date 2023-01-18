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
* Values chosen by test authors.
* Can be used within a test's `run` block to modify test behavior.
* Can modify inputs/outputs/requests to avoid naming collisions.
* Can modify input properties such as whether an input is required or locked.
* Can define custom boot-time options which are used within a test's `run` block
  to modify test behavior.

### Suite Options

* Only defined at the suite level.
* Evaluated at test session creation time.
* Values chosen by test users.
* Can modify which tests/groups appear in the UI and are executed.
* Can be used within a test's `run` block to modify test behavior.

## Configuration

Configuration provides a way for test authors to avoid naming conflicts when
reusing tests and set boot-time options. For example, a suite may want to run a
particular group twice with distinct inputs and outputs. Those groups can be
configured so that their inputs and outputs are distinct from each other without
having to alter the group itself. Additionally, configuration can change input
properties such as whether a particular input is locked or required.

When a runnable defines some configuration, that configuration also applies to
all of that runnable's children. Configuration defined by a parent runnable
overrides any child runnable's configuration.

### Renaming Inputs/Outputs/Requests

Renaming inputs and outputs allows test authors to handle potential naming
conflicts when using the same tests multiple times, or using tests from multiple
sources with differently named inputs.


Consider a test group which needs to check which versions of TLS are
supported by two different servers. This group can use [this test which checks
which TLS versions a server
supports](https://github.com/inferno-framework/tls-test-kit/blob/main/lib/tls_test_kit/tls_version_test.rb)
based on a `url` input. In order to check the TLS versions supported by two
different servers, `config` can be used to make each instance of this test use a
different input.

```ruby
class MyTestGroup < Inferno::TestGroup
  input :source_server_url
  input :destination_server_url
  
  # Inline config
  test from: :tls_version_test,
       id: :source_server_tls_test,
       config: {
         inputs: {
           url: { name: :source_server_url }
         }
       }
       
  # Config within test block
  test from: :tls_version_test do
    id :destination_server_tls_test
    config(
      inputs: {
        url: { name: :destination_server_url }
      }
    )
  end
end
```

Outputs and requests can be renamed in the same fashion, using `outputs` or
`requests` as the key in `config`.

### Altering Input Properties

In addition to renaming an input, other input properties can be altered as well.
Any of the [input
options](https://inferno-framework.github.io/inferno-core/docs/Inferno/DSL/InputOutputHandling.html#input-instance_method)
used to define an input can be changed.

For example, for SMART App Launch STU 1, PKCE support is optional. The following
inputs are defined to let users choose whether to use PKCE during testing:

```ruby
class StandaloneLaunchGroup < Inferno::TestGroup
  # ...
  input :use_pkce,
        title: 'Proof Key for Code Exchange (PKCE)',
        type: 'radio',
        default: 'false',
        options: {
          list_options: [
            {
              label: 'Enabled',
              value: 'true'
            },
            {
              label: 'Disabled',
              value: 'false'
            }
          ]
        }
  input :pkce_code_challenge_method,
        optional: true,
        title: 'PKCE Code Challenge Method',
        type: 'radio',
        default: 'S256',
        options: {
          list_options: [
            {
              label: 'S256',
              value: 'S256'
            },
            {
              label: 'plain',
              value: 'plain'
            }
          ]
        }
  # ...
end
```

For SMART App Launch STU 2, PKCE support is required, and it is required that
PKCE use the S256 code challenge method. The same launch tests are reused for
STU 2, but the inputs are configured to require PKCE with the S256 code
challenge method. The defaults are set to the required value, and the inputs are
locked to prevent users from changing them.

```ruby
class StandaloneLaunchGroupSTU2 < StandaloneLaunchGroup
  # ...
  config(
    inputs: {
      use_pkce: {
        default: 'true',
        locked: true
      },
      pkce_code_challenge_method: {
        default: 'S256',
        locked: true
      }
    }
  )
  # ...
end
```

### Custom Configuration Options

Custom configuration options allow information to be loaded at boot time and
made available to tests. For example, a test could have optional functionality
which is enabled by setting a specific configuration option value.

[This test which checks which TLS versions a server
supports](https://github.com/inferno-framework/tls-test-kit/blob/main/lib/tls_test_kit/tls_version_test.rb)
allows test authors to set the minimum and maximum allowed TLS versions. This
gives the test the flexibility to be used in a variety of different testing
scenarios with different TLS requirements. The test's configuration options are
[described in its
README](https://github.com/inferno-framework/tls-test-kit/#using-the-tls-test-in-other-test-suites)
For example, the Bulk Data Implementation Guide requires that TLS 1.2 or later
be used, so Inferno bulk data tests can configure the TLS test as follows:

```ruby
test from: :tls_version_test,
     config: {
       options: {  minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION }
     }
```

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
the selected suite options by defining `required_suite_options`. In the
following example (using the suite option definition from above), the user will
only see the SMART App Launch group for the version which they selected when
starting their session.

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
