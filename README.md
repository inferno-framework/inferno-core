# Inferno Core
[![codecov](https://codecov.io/gh/inferno-framework/inferno-core/branch/main/graph/badge.svg?token=6NJTBHF82R)](https://codecov.io/gh/inferno-framework/inferno-core)

Inferno Core is the central component of the [Inferno
Framework](https://inferno-framework.github.io) that allows you to write,
execute, and distribute executable API conformance tests for the [HL7® FHIR®
standard](http://hl7.org/fhir/) standard.

To learn how to use the Inferno Framework and Inferno Core to develop your own
FHIR API tests, visit [Inferno Framework
Documentation: Getting Started for Inferno Test Writers](https://inferno-framework.github.io/inferno-core/getting-started.html#getting-started-for-inferno-test-writers).
If you'd like to get started right away, clone the [Inferno Test Kit Template
repository](https://github.com/inferno-framework/inferno-template) which
provides a pre-configured project with Inferno Core that you can use to
start creating tests.

## About Inferno Core
Inferno Core is a [Ruby](https://ruby-lang.org/) library used to create
Ruby-based test applications (called Inferno Test Kits) and provides features
useful for writing and executing FHIR API tests:

* **Inferno DSL**: A domain specific language for authoring FHIR API tests that
  includes a FHIR client, native Ruby classes for FHIR, and FHIR instance validators
* **API, Web and CLI Interfaces**: Multiple interfaces for executing tests and
  retrieving results
* **Test Reuse**: Methods for reusing tests within a project or from other projects

Because tests are written as Ruby scripts, test writers are able to leverage a
fully-featured programming language and a rich ecosystem of open source
third-party libraries to write their tests if needed.  This makes Inferno
well-suited for testing data exchanges that:

* include the use of additional standards beyond FHIR,
* have large specifications that could benefit from Ruby's meta-programming
  capabilities to ease maintenance burden,
* or require complex logic to thoroughly validate API responses.

Inferno Core provides common utilities for FHIR-based testing, but tests are not
limited to what is provided by Inferno Core.  Inferno Core's goal is to expand on
the set of common utilities it provides for the benefit of the community.

To learn more about Inferno Framework and Inferno Core, please visit:
- [Inferno Framework documentation](https://inferno-framework.github.io/inferno-core/)
- [Inferno Core Ruby API documentation](https://inferno-framework.github.io/inferno-core/docs)
- [Inferno Core JSON API documentation](https://inferno-framework.github.io/inferno-core/api-docs)

## Contributing to Inferno Core

Inferno Core contains functionality that should be broadly useful for testing
any FHIR-based data exchange, and the team welcomes contributions.  Developers
interested in contributing to the Inferno Core gem must have [Ruby
3.1+](https://www.ruby-lang.org/en/) and [Node.js and
NPM](https://www.npmjs.com/get-npm) installed.

If you are interested in developing tests using Inferno Core, use the [Inferno
Template Repository](https://github.com/inferno-framework/inferno-template).
These instructions are for developers working on Inferno Core itself.

## Running Inferno Core for Development Purposes
```
# Install dependencies
npm install
bundle install
gem install foreman

# Set up database
bin/inferno migrate

# Start Inferno background services (validator, redis, nginx)
bin/inferno services start
# Start web server, worker, and webpack
bin/inferno start

# When you're done, stop the background services
bin/inferno services stop
```

Inferno Core can then be accessed by navigating to
[http://localhost:4567/inferno](http://localhost:4567/inferno)

To only run the server (JSON API with no UI): `bundle exec puma`

If you would like to test other test suites with changes being made
to Inferno Core, you may do so by following the instructions
provided in the Gemfile:

```ruby
# To test with the g10 test kit (this also adds the US Core, SMART, and TLS test
# kits):
# - Uncomment this line (and change test kit gem as necessary):
# gem 'onc_certification_g10_test_kit'

# - Run `bundle`
# - Uncomment (and change as necessary) the require at the top of
# `dev_suites/dev_demo_ig_stu1/demo_suite.rb`.

```

## Running tests via JSON API
With the server running, first retrieve a list of available test suites:
```
GET http://localhost:4567/inferno/api/test_suites
```
See the details of a test suite:
```
GET http://localhost:4567/inferno/api/test_suites/TEST_SUITE_ID
```
Then create a test session for the suite you want to use:
```
POST http://localhost:4567/inferno/api/test_sessions?test_suite_id=TEST_SUITE_ID
```
Tests within a suite are organized in groups. Create a test run to run an entire
suite, a group, or an individual test. Only one of `test_suite_id`,
`test_group_id`, or `test_id` should be provided.
```
POST http://localhost:4567/inferno/api/test_runs
{
  "test_session_id": "TEST_SESSION_ID",
  "test_suite_id": "TEST_SUITE_ID",
  "test_group_id": "TEST_GROUP_ID",
  "test_id": "TEST_ID",
  "inputs": [
    {
      "name": "input1",
      "value": "input1 value"
    },
    {
      "name": "input2",
      "value": "input2 value"
    }
  ]
}
```
Then you can view the results of the test run:
```
GET http://localhost:4567/inferno/api/test_runs/TEST_RUN_ID/results
or
GET http://localhost:4567/inferno/api/test_sessions/TEST_SESSION_ID/results
```

## Running on Windows
Inferno Core requires a WSL instance in order to run.  Instructions for setting 
that up can be found at the [Inferno Framework documentation](https://inferno-framework.github.io/inferno-core/getting-started.html#development-with-ruby)

## Development in a Ruby console
To get to an interactive console, run `bundle exec bin/inferno console`

## Customizable Banner
Inferno Core allows you to add your own customizable banner. It loads the banner
from the `config/banner.html.erb` file and renders it above the application. The
size and appearance of the banner can be controlled by using the inline style
attribute.

## Documentation
Inferno documentation source code is located in the `docs/` directory. This
documentation is rendered using Jekyll, which creates a site that can be built
and served with:

```sh
cd docs/
bundle install
bundle exec jekyll serve
```
By default the site will be served at `http://localhost:4000/inferno-core/`

## License

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

## Trademark Notice

HL7, FHIR and the FHIR [FLAME DESIGN] are the registered trademarks of Health
Level Seven International and their use does not constitute endorsement by HL7.
