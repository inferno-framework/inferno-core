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
`--update-expected` (`-u`). Expected results files are overwritten with the
actual results (pretty-printed) whenever their stored content would change,
instead of writing actual results and comparison files, and the comparison is
treated as passing. This includes files whose results still match but that were
written in an older format or with different normalizations, so `-u` also
brings those up to date. Files that are already current aren't rewritten.
Review the changes with `git diff` before committing.

Expected results files (and the actual results files written on a mismatch)
contain only the fields used in comparison: the result's test, group, or suite id,
`result`, `result_message`, `messages` (type and message), `requests` (direction,
verb, URL, and status), and `inputs`/`outputs` (name and value). To get a
session's full results (including result and request ids and timestamps), use
`inferno session results SESSION_ID`.

These files are stored in normalized form, so regenerating expected results only
changes the file when compared content changes. Normalizations are applied in this
order:

1. Session ids are replaced with `<NAME.session_id>` placeholders.
2. The Inferno base URL (with or without its scheme's default port, e.g., `:443`)
   is replaced with `<inferno_base_url>` and ISO 8601 timestamps with `<TIMESTAMP>`.
3. The script's `normalized_strings` are applied. Because they run after the steps
   above, rules can match those placeholders, e.g.
   `/<inferno_base_url>\/custom\/demo\/resume\?token=\w+/` normalizes a whole resume
   URL regardless of which Inferno the script runs against.
4. Any remaining 64-character lowercase hex values (e.g., wait identifiers created
   with `SecureRandom.hex(32)`) are replaced with `<RANDOM_64_CHAR_HEX>`. This runs
   last so that a script's own rules for these values take precedence.

Set `comparison_config.default_normalizations: false` in a script to skip steps 2
and 4 and compare those values exactly.

Normalization is also applied when comparing, so adding a rule doesn't require
regenerating, but after changing or removing a rule (or renaming a session),
regenerate the affected expected results with `-u`.

The standalone `inferno session compare -f` command applies the default
normalizations (steps 2 and 4) for the Inferno given with `-I` (or the default
base URL), but it doesn't know the script's sessions or its `normalized_strings`.
Compare files that contain `<NAME.session_id>` placeholders or depend on the
script's rules by running the script.

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
