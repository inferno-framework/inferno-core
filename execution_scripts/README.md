# Using Core Execution Scripts

This directory contains inferno-core execution scripts that
demonstrate and validate the behavior of script execution
as well as the functionality with in the suites in the
sibling `dev_suites` folder.

Unlike test kit execution scripts, these scripts can be expected
to fail in order to demonstrate particular features of
script execution or of inferno in general. These scripts must
include the `_failure.yaml` suffix so that the github workflow
and the rake file execution know to expect a failure.