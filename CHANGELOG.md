# 0.2.0.rc3

* Update the UI to improve accessibility.
* Update the route users are redirected to after coming back to resume a waiting
  test.
* Add presets for US Core, SMART App Launch, and ONC Certification (g)(10) test
  kits to assist with development.

# 0.2.0.rc2

* Bust the bundle.js cache.
* Make entire test list item clickable.

# 0.2.0.rc1

* **Breaking Change:** Support hosting inferno on a non-root path. To support
  hosting inferno at a non-root path, it was necessary to change how inferno's
  static assets are being served. Any test kit upgrading to use version 0.2.0 or
  later of Inferno Core will need to replace `config.ru` with [the updated
  `config.ru` in the inferno
  template](https://raw.githubusercontent.com/inferno-framework/inferno-template/main/config.ru).
* Fix a bug which prevented individual tests from running.
* Add `version` field to test suites.
* Ui improvements.
* Retry database connections at startup.
* Support loading external test kits when developing Inferno Core.
* Add the ability to check test suite configuration. Currently only error
  messages are displayed in the UI.
* Add short identifiers to all tests in a test suite.
* Update the UI so that any groups marked `run_as_group` are displayed with all
  of their children, rather than requiring navigating into each child
  separately.
* Add a report view.
* Display Inferno Core and test kit versions in the UI.
* Support preset inputs.

# 0.1.3

* Fix a bug where `oauth_credentials` inputs were not locked when they should
  be.
* Fix a bug causing an error when cancelling tests.
* Fix a bug with how required inputs are determined.
* Remove 'required' label from radio buttons, and automatically select the first
  option if no default is specified.
* Major UI improvements. Changed location of run buttons and added a button to
  start a new test session in addition to cosmetic updates.
* Update ruby and js dependencies to address security vulnerabilities.

# 0.1.2

* Add the ability to cancel a test run.
* When configuration changes are applied to a runnable, they are now applied to
  all of its children.
* Update sidekiq.

# 0.1.1

* Add `input_instructions`, `short_title`, and `short_description` to runnables.
  UI for these attributes is not yet implemented.
* Fix an issue where Omit results had higher precedence than Pass results
* Add support for HTTP delete requests and streaming get requests
* Minor UI improvements
* Improve the UI for `oauth_credentials` inputs
* Allow tests/groups to be marked as optional

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
