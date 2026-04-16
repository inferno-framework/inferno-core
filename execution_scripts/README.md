# Using Core Execution Scripts

This directory contains inferno-core [execution scripts](https://inferno-framework.github.io/docs/advanced-test-features/scripting-execution.html)
that demonstrate and validate the behavior of script execution
as well as the functionality with in the suites in the
sibling `dev_suites` folder. Execution scripts defined here will
be [executed](https://inferno-framework.github.io/docs/advanced-test-features/scripting-execution.html#execution)
automatically on pull requests as a part of the github
workflows and can also be executed locally using the
[`execute_script` CLI](https://inferno-framework.github.io/docs/getting-started/inferno-cli.html#complex-scripted-execution)
on individual scripts or the `execute_scripts:run_all` rake task.

Unlike test kit execution scripts, these scripts can be expected
to error in order to demonstrate particular features of
script execution or of inferno in general such as
- loop detection or canceled wait state (error in the script definition).
- missing --with-commands flag (error in the execution command or script naming)
These scripts must
include the `_error.yaml` suffix so that the github workflow
and the rake file execution know to expect an error in the execution.

Note that this is different than expected `fail` results, which are valid
non-passing results for tests: these can be recorded as expected within
the expected results file.