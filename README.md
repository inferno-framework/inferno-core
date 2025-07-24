# Inferno Core
[![codecov](https://codecov.io/gh/inferno-framework/inferno-core/branch/main/graph/badge.svg?token=6NJTBHF82R)](https://codecov.io/gh/inferno-framework/inferno-core)

Inferno Core is the central library of the [Inferno
Framework](https://inferno-framework.github.io) that allows you to write,
execute, and distribute executable conformance tests for the [HL7® FHIR®
standard](http://hl7.org/fhir/) standard. Inferno Core isn't built to be used
alone; it is imported as a library into Inferno Test Kits, which are web-based
testing applications that target specific data exchange use cases enabled by
FHIR.

To learn how to use the Inferno Framework and Inferno Core to develop your own
Inferno Test Kit, visit [Inferno Framework Documentation: Getting Started for
Inferno Test
Writers](https://inferno-framework.github.io/docs/getting-started/).

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
- [Inferno Framework documentation](https://inferno-framework.github.io/docs/)
- [Inferno Core Ruby API documentation](https://inferno-framework.github.io/inferno-core/docs)
- [Inferno Core JSON API documentation](https://inferno-framework.github.io/inferno-core/api-docs)

## Contributing to Inferno Core

Inferno Core contains functionality that should be broadly useful for testing
any FHIR-based data exchange, and the team welcomes contributions.

Developers
interested in contributing to the Inferno Core gem must have [Ruby
3.1+](https://www.ruby-lang.org/en/), [Node.js and
NPM](https://www.npmjs.com/get-npm), and [Docker
Desktop](https://www.docker.com/products/docker-desktop/) installed.
[Podman](https://podman.io/) may be used an alternative to Docker Desktop.

Inferno Core development is supported within MacOS, Linux or Windows environments.
However, Windows development currently requires the use of WSL2.  Please visit
the [Inferno Framework
documentation](https://inferno-framework.github.io/docs/getting-started/#development-with-ruby)
site for more information.

## Running Inferno Core for Development Purposes
```
# Install dependencies
npm install
bundle install
gem install foreman

# Set up database
bin/inferno migrate

# Start Inferno background services using Docker/Podman (validator, redis, nginx)
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

## Development in a Ruby console
To get to an interactive console, run `bundle exec bin/inferno console`

## Updating the FHIR Resource Validator
Inferno relies on a java service to validate FHIR resources. [The validator
directory](https://github.com/inferno-framework/inferno-core/tree/main/validator)
contains the Dockerfile used to build this validator and instructions for
updating it.

## Documentation
Inferno Core documentation has primarily moved to the
[Inferno Framework documentation site](https://github.com/inferno-framework/inferno-framework.github.io/).
However, Ruby Docs (generated from the source code using `./bin/docs`) and the Swagger API
documentation is still located within the `docs/` directory. This documentation
is rendered using Jekyll, which creates a site that can be built and served
with:

```sh
./bin/docs
cd docs/
bundle install
bundle exec jekyll serve
```

View the Ruby Docs at [http://localhost:4000/inferno-core/docs](http://localhost:4000/inferno-core/docs) and the API Docs at
[http://localhost:4000/inferno-core/api-docs](http://localhost:4000/inferno-core/api-docs).

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
