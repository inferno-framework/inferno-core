---
title: Test Properties
nav_order: 2
parent: Writing Tests
---
# Test/Suite/Group Properties
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Title
The title which is displayed in the UI:
```ruby
test do
  title 'US Core Patient Read Interaction'
end
```
[`title` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#title-instance_method)

## Short Title
A short title which is displayed in the left side of the UI:
```ruby
group do
  short_title 'Patient Tests'
end
```
[`short_title` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#short_title-instance_method)

## Id
A unique identifier for a test/group/suite. Inferno will automatically create
ids if they are not specified. It is important to create ids yourself if you
need to refer to a test/group elsewhere, such as to include one in another
group.

TestSuite ids appear in Inferno's urls, so consideration should be given to
choosing a suite id that will make sense to users as a url path. Links to a test
suite take the form of `INFERNO_BASE_PATH/TEST_SUITE_ID`, and individual test
session urls look like `INFERNO_BASE_PATH/TEST_SUITE_ID/TEST_SESSION_ID`.
```ruby
test do
  id :us_core_patient_read
end

group do
  test from: :us_core_patient_read
end
```
[`id` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#id-instance_method)

## Description
A detailed description which is displayed in the UI.
[Markdown](https://commonmark.org/help/) is supported. There are several ways to
define long strings in ruby:

```ruby
test do
  description 'This is a brief description'
  
  description 'This is a longer description. There are several ways to split ' \
              'it up over multiple lines, and this is one of the worst ways.'
              
  description <<~DESCRIPTION
    This is another long description. This is an ok way to represent a long
    string in ruby.
  DESCRIPTION
  
  description %(
    This is another long description. This is a pretty good way to represent a
    long string in ruby.
  )
end
```
[`description` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#description-instance_method)

## Optional/Required
Mark a test/group as optional/required. Tests/Groups are required by default.
The results of optional tests do not affect the test result of their parent.

```ruby
group do
  optional # Makes this group optional

  test do
    optional # Makes this test optional
  end
  
  test from: :some_optional_test do
    required # Make an optional test required
  end
end
```
[`optional` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#optional-instance_method)

[`required` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#required-instance_method)

## Run
(`Test`s only) `run` defines a block of code which is executed when the test is
run. A test will typically make one or more
[assertions](/inferno-core/docs/Inferno/DSL/Assertions.html). If no assertions fail, then the
test passes.
```ruby
test do
  run do
    assert 1 == 0, 'One is not equal to zero'
  end
end
```
[`run` in the API
docs](/inferno-core/docs/Inferno/Entities/Test.html#block-class_method)

## Version
(`TestSuite`s only) Define the suite's version, which is displayed in the UI.
```ruby
class MySuite < Inferno::TestSuite
  version '1.2.3'
end
```
[`version` in the API
docs](/inferno-core/docs/Inferno/Entities/TestSuite.html#version-class_method)

## Input Instructions
Define additional instructions which will be displayed above a runnable's
inputs. These instructions only appear when running this particular runnable.
They will not appear if you run a parent or child of this runnable.
[Markdown](https://commonmark.org/help/) is supported.
```ruby
group do
  input_instructions %(
    Register Inferno as a standalone application using the following information:

    * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

    Enter in the appropriate scope to enable patient-level access to all
    relevant resources. If using SMART v2, v2-style scopes must be used. In
    addition, support for the OpenID Connect (openid fhirUser), refresh tokens
    (offline_access), and patient context (launch/patient) are required.
  )
end
```
[`input_instructions` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#input_instructions-instance_method)

## Run as Group
(`Group`s only) `run_as_group` makes a group run as a single unit. When true,
users will not be able to run any of the group's children individually. They
will only be able to run the whole group at once.
```ruby
group do
  run_as_group

  # These tests can not be run individually
  test do
    # ...
  end

  test do
    # ...
  end
end
```
[`run_as_group` in the API
docs](/inferno-core/docs/Inferno/Entities/TestGroup.html#run_as_group-class_method)

## Suite Option
(`TestSuite`s only) Define a user-selectable option for a suite. See [Suite
Options
documentation](/inferno-core/writing-tests/test-configuration.html#suite-options-1).
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
[`suite_option` in the API
docs](/inferno-core/docs/Inferno/Entities/TestSuite.html#suite_option-class_method)

## Required Suite Options
(`Test`s/`Group`s only) Define the suite options which must have been selected
in order for a runnable to be included in the current session. See [Hiding Tests
Based on Suite
Options](/inferno-core/writing-tests/test-configuration.html#hiding-tests-based-on-suite-options).
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
[`required_suite_options` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#required_suite_options-instance_method)

## Links
(`TestSuite`s only) Define a list of links which are displayed in the footer of
the UI.
```ruby
class MyTestSuite < Inferno::TestSuite
  links [
    {
      label: 'Report Issue',
      url: 'https://github.com/onc-healthit/onc-certification-g10-test-kit/issues/'
    },
    {
      label: 'Open Source',
      url: 'https://github.com/onc-healthit/onc-certification-g10-test-kit/'
    }
  ]
end
```
[`links` in the API
docs](/inferno-core/docs/Inferno/Entities/TestSuite.html#links-class_method)

## Suite Summary
(`TestSuite`s only) Define a summary which is displayed on the suite options
selection page. If the suite has no options, the summary is not used. If no
suite summary is defined, the description will be displayed on the options
selection page.
```ruby
class MyTestSuite < Inferno::TestSuite
  suite_summary %(
    This is a brief description of the suite which will be displayed on the
    suite options selection page.
  )
end
```
[`suite_summary` in the API
docs](/inferno-core/docs/Inferno/Entities/TestSuite.html#suite_summary-class_method)

## Config
Configure a runnable and its descendants. For more information, see
[Configuration](/inferno-core/writing-tests/test-configuration.html#configuration-1).

[`config` in the API
docs](/inferno-core/docs/Inferno/DSL/Configurable.html#config-instance_method)
