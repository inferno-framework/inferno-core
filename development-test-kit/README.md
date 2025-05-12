# Development Test Kit

This test kit is designed to be used during [Inferno](https://github.com/inferno-community/inferno-core) Core development. It contains various example test suites that demonstrate different features and capabilities of the Inferno testing framework.

## Purpose

The Development Test Kit serves several purposes:
- Provides example test suites for testing and validating Inferno Core functionality
- Demonstrates various Inferno testing features and patterns
- Serves as a reference for developing new test kits
- Helps in testing infrastructure changes to Inferno Core

## Test Suites Included

- **Infrastructure Test Suite**: An internal test suite to verify that inferno infrastructure works
- **Demonstration Suite**: Development suite for testing standard inputs and results
- **AuthInfo Suite**: Demonstrates authentication information handling
- **Custom Result Suite**: Shows custom result handling
- **Options Suite**: Demonstrates suite options functionality
- **Requirements Suite**: Shows requirements verification
- **Validator Suite**: Makes calls to the HL7 Validator

## Getting Started

Since this test kit is meant to be used within the Inferno Core development environment, you'll need to:

1. Clone the Inferno Core repository
2. Navigate to the development-test-kit directory
3. Run `bundle install` to install dependencies
4. Start services using `../bin/inferno services start`
5. Start the test kit using `../bin/inferno console` or `../bin/inferno start`

Note: Unlike standalone test kits, this one is designed to run from within the
Inferno Core project structure, which is why we use `../bin/inferno` instead of
the standard Inferno commands.

This should be updated at the same time any changes are made to core that require
test kit updates.  Note that this should be done in concert with updates to the template.

## Documentation
- [Inferno documentation](https://inferno-framework.github.io/docs/)
- [Ruby API documentation](https://inferno-framework.github.io/inferno-core/docs/)
- [JSON API documentation](https://inferno-framework.github.io/inferno-core/api-docs/)

## License
Copyright 2025 The MITRE Corporation

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
