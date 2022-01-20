# 0.1.0

* Fix a display bug for url-encoded request bodies
* Minor UI improvements
* Display a modal when tests are in a wait state
* Add initial support for PostgreSQL
* Add support for radio button inputs
* Add a new `oauth_credentials` input type and the ability to automatically
  refresh OAuth2 access tokens

# 0.0.8

* Update Material UI to v5
* Various UI improvements
* Update fhir_client version
* Add support for search with POST to FHIR Client
* Add support for adding additional validation functions
* Fix issue where entire response bodies were always logged
* Fix a migration error

# 0.0.7

* Add [documentation in github pages](https://inferno-framework.github.io/inferno-core/)
* Add ability to lock inputs
* Add initial version of `inferno` CLI command.
  * **Breaking change:** migrations are no longer run automatically. They can be
    run manually with `inferno migrate`. This will also break unit tests in test
    kit repos. Test kit repos should add these lines above the line with
    `require 'inferno'` in `spec/spec_helper.rb`:
    ```
    require 'inferno/config/application'
    require 'inferno/utils/migration'
    Inferno::Utils::Migration.new.run
    ```

# 0.0.6

* Fix long request URLs pushing buttons off screen
* Add ability to declare inputs optional
* Prevent multiple simultaneous test runs within a single session
* Add ability to declare that tests must be run as a group
* Add temporary in-memory storage for use within a test run
* Add ability to configure tests

# 0.0.5

* Fix sidekiq dependency

# 0.0.4

* Add bearer token support to FHIR Client DSL
* Add ability to serve custom endpoints from a test suite
* Run tests asynchronously and support resuming a test run
* Add ability to set default input values
* Update UI to populate inputs with session data
* Update UI to distinguish between requests a test makes vs. those it uses

# 0.0.3

* Include factories in gem

# 0.0.2

* Initial working gem release

# 0.0.1

* Initial gem release
