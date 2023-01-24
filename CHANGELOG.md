# 0.4.8
* Fix a bug which removed the refresh token during automatic refreshes if the
  token refresh response did not contain a new refresh token.
* Add the ability for presets to contain values which depend on the selected
  suite options.
* Prevent manually expanded groups from automatically closing when tests run.
* Display warning and error message indicators at the group level.
* Expand the clickable area for groups in the navigation tree.
* Update page titles.
* Update vulnerable dependencies.

# 0.4.7
* Add a home link to logo and suite title in header.
* Update the header to make to minimize size on mobile devices.
* Update the error message in response status and resource type assertions.

# 0.4.6
* Add DSL support for the FHIR batch/transaction interaction.

# 0.4.5
* Remove the copy button and url truncation from print view.
* Improve the display for runnables in the ruby console.
* Display in-progress icons for running tests.
* Indicate incoming requests with an icon rather than incoming/outgoing labels.
* Remove timestamps from headers and messages tables.
* Remove id/title tooltips.
* Automatically open groups with a skip result.
* Add DSL support for the FHIR create interaction.

# 0.4.4
* Update hanami-router to fix a bug which prevented Inferno from handling inputs
  containing `%` characters.

# 0.4.3
* Remove timestamps from headers and messages.

# 0.4.2
* Add a missing require to the session data repository.
* Fix UI bugs.

# 0.4.1
* Fix a routing issue which made Inferno unavailable on the root of a domain in
  test kits.
* Fix a bug which could cause flashing on the suite selection screen.

# 0.4.0
* **Breaking Change:** Inferno has been updated to use Ruby 3.1.
* Add the ability to use CTRL/CMD+Enter to submit inputs and start a test run.

# 0.3.12
* Fix the ordering of requests in the UI.
* Fix a memory leak.
* Fix the order in which `.env*` files are loaded.
* Add the ability to copy request urls from the Inferno UI.
* Add a toggle to the report view to show/hide messages and requests.
* Reduce the size of report pdfs.
* Add commands to the CLI to start inferno and required background services.
* Improve the Inferno UI for mobile devices.
* Various other UI improvements.

# 0.3.11
* Update fhir_models to address an issue where models were being instantiated
  slightly differently depending on whether they were instantiated from a string
  or a hash.
* Update the UI to sort the list of suites alphabetically.
* Fix an issue which prevented markdown tables from rendering in messages.
* Update the header's scrolling behavior.

# 0.3.10
* Fix a performance issue when creating a test run for a large test suites.
* Improve the test details UI.

# 0.3.9
* Improve options selection UI background color when a banner is used.
* Add suite_summary field that is displayed on suite options/landing page.

# 0.3.8
* Improve options selection UI.
* Fix bug where test count was not taking suite options into account.

# 0.3.7
* Fix bug displaying request details.

# 0.3.6
* Improve logic for automatically opening failed tests after test run.
* Improve accessibility for touch screen users.
* Add suite-configurable links to the footer.
* Fix bug where suite options did not properly filter sub-groups.
* Display selected options in header, if applicable.
* Display selected options in report, if applicable.
* Implement input filtered based on selected option.
* Improve option selection page.
* Update http client to automatically follow redirects.
* Visually improve request/message count badges for large numbers.
* Allow presets to use erb templates to allow environment-specific values.
* Allow API users to leave session creation request body empty.

# 0.3.5
* Add initial UI and JSON API support for suite options.
* Fix an issue which prevented users from selecting text in group item headers.
* Fix an issue where inputs added to a group after creation were not added to
  the group's children.
* Lock the `dry-container` version to prevent it from being updated to a version
  with breaking changes.

# 0.3.4

* Incorporate UI changes to improve info, warning, and error test message readability. 
* Update to support running locally on M1 MacBooks. 
* Update gem dependencies. 
* Add deployment documentation - SSRF protection and SSL, database, and path 
  configuration.
* Include links to Inferno's github repository and issues page in testing view.
* Improve frontend storage.
* Implement backend support for suite options: this allows test writers to specify which 
  tests in a suite are executed and which validator to use during execution. 
* Add touchscreen support.

# 0.3.3

* UI accessibility improvements.
* Force sending text/html Content-Type header for app root and session pages.

# 0.3.2

* Add IE meta tag.
* Add accessibility design and features to UI.
* Update to tests so missing named requests raise a skip instead of error.
* Update to test view so JSON requests are formatted more readably.
* Preset options now sorted and presented alphabetically.
* Various minor UI improvements.

# 0.3.1

* Fix a bug which prevented a session from loading if it had results which
  referred to a test which had been removed or whose id had changed.
* Fix an bug which caused only the first page to appear in the print report
  view.

# 0.3.0

* Various minor UI improvements
* Improve how inputs are handled in the backend so that the UI can display
  inputs exactly as received from the JSON api rather than needing to determine
  which inputs to display itself.
* Add the ability to specify the order in which inputs appear in the UI.
* Add the ability to copy/paste JSON/YAML versions of inputs in the UI.
* Update the preset input selection UI.
* Add inputs/outputs to test and report displays in the UI.
* Add the ability to display a custom banner at the top of the page.
* Update the UI for suite configuration messages. Info and warning messages will
  now be displayed in addition to error messages.
* Update the UI to not omit required indicators from locked inputs.
* Fix a bug where sometimes in an input would appear twice in the UI.
* Fix a bug where the *New Session* button was using the wrong url.
* Fix a bug where primitive extensions were stripped from resources before they
  were validated.
* Fix a bug where a test run could be created without all of the required
  inputs.

# 0.3.0.rc1
* Initial release candidate for 0.3.0

# 0.2.0

# 0.2.0.rc4

* Allow erb in db config.
* UI appearance updates and performance improvements.
* Update documentation.

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
