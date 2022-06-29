# Inferno Core
[![codecov](https://codecov.io/gh/inferno-framework/inferno-core/branch/main/graph/badge.svg?token=6NJTBHF82R)](https://codecov.io/gh/inferno-framework/inferno-core)

Inferno Core is an open source tool for testing data exchanges enabled by the [Fast
Healthcare Interoperability Resources (FHIR)](http://hl7.org/fhir/) standard. 

If you are interested in developing tests using Inferno Core, use the [Inferno
Template Repository](https://github.com/inferno-framework/inferno-template).

## Documentation
- [Inferno documentation](https://inferno-framework.github.io/inferno-core/)
- [Ruby API documentation](https://inferno-framework.github.io/inferno-core/docs)
- [JSON API documentation](https://inferno-framework.github.io/inferno-core/api-docs)

## Contributing to Inferno Core
Developers interested in contributing to the Inferno Core gem must have [Ruby
2.7+](https://www.ruby-lang.org/en/) and [Node.js and
NPM](https://www.npmjs.com/get-npm) installed.

## Using Inferno Core to author tests

If you are interested in developing tests using Inferno Core, use the [Inferno
Template Repository](https://github.com/inferno-framework/inferno-template).
These instructions are for developers working on Inferno Core itself.

```
# Install dependencies
npm install
bundle install

# Set up database
bundle exec bin/inferno migrate

# Start Inferno Core server and UI
npm run dev
```

Inferno Core can then be accessed by navigating to
[http://localhost:4567/inferno](http://localhost:4567)

To only run the server (JSON API with no UI): `bundle exec puma`

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

## Development
To get to an interactive console, run `bundle exec bin/inferno console`

## Customizable Banner
Inferno Core allows you to add your own customizable banner. It loads the banner from the `config/banner.html.erb` file and renders it above the application. The size and appearance of the banner can be controlled by using the inline style attribute. 

## Documentation
Inferno documentation source code is located in the `docs/` directory. This documentation is rendered using Jekyll, which creates a site that can be built and served with: 

```sh
cd docs/
bundle install
bundle exec jekyll serve
```
By default the site will be served at `http://localhost:4000/inferno-core/`


## License
Copyright 2022 The MITRE Corporation

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
