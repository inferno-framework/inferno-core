# Using Core Execution Scripts

This directory contains [execution scripts](https://inferno-framework.github.io/docs/advanced-test-features/scripting-execution.html)
that demonstrate and validate the behavior of suites defined
by this test kit in the context of running Inferno services
allowing for end-to-end executions that check for expected suite execution
results when using Inferno services like the FHIR Validator and FHIR Path
Service as well as dependency services that Inferno does not control such
as `tx.fhir.org`.

Execution scripts defined here will
be [executed](https://inferno-framework.github.io/docs/advanced-test-features/scripting-execution.html#execution)
automatically on pull requests as a part of the GitHub
workflows and can also be executed locally using the
[`execute_script` CLI](https://inferno-framework.github.io/docs/getting-started/inferno-cli.html#complex-scripted-execution).
If no `.yaml` files are found under this directory, the GitHub workflow will be skipped.

## Updating Expected Results

When a change intentionally alters results, run the affected scripts with
`--update-expected` (`-u`). Expected results files that don't match are
overwritten with the actual results (pretty-printed) instead of writing
actual results and comparison files, and the comparison is treated as passing.
Review the changes with `git diff` before committing.

```
bundle exec inferno execute_script -u execution_scripts/path/to/script.yaml
```

## Cleaning Up Result Files

When a script's results don't match its expected results file, the
`*_actual_results_<timestamp>.json` and `*_compared_results_<timestamp>.csv`
files are written next to the expected results file. These files are
ignored by git, so once they are no longer needed they can be removed with
`git clean`:

```
# List the files that would be removed
git clean -nX execution_scripts

# Remove them
git clean -fX execution_scripts
```

Note that `-X` removes all git-ignored files under `execution_scripts`, not only
result files, so check the dry run output first if you keep other ignored files there.
