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
This suffix is recognized by the GitHub CI/CD action and the rake task,
but not by CLI execution.

Note that this is different than expected `fail` results, which are valid
non-passing results for tests: these can be recorded as expected within
the expected results file.

## Updating Expected Results

When a change intentionally alters results, run the affected scripts with
`--update-expected` (`-u`). Expected results files are overwritten with the
actual results (pretty-printed) whenever their stored content would change,
instead of writing actual results and comparison files, and the comparison is
treated as passing. Files that are already current aren't rewritten.
Review the changes with `git diff` before committing.

Expected results files (and the actual results files written on a mismatch)
contain only the fields used in comparison: the result's test, group, or suite id,
`result`, `result_message`, `messages` (type and message), `requests` (direction,
verb, URL, and status), and `inputs`/`outputs` (name and value). To get a
session's full results (including result and request ids and timestamps), use
`inferno session results SESSION_ID`.

To skip a comparison for every script in a run, use its command line flag
(`--no-compare-messages`, `--no-compare-result-message`, `--no-compare-requests`, or
`--no-compare-io`). The flags don't change what's stored. To turn a comparison off
for a script, e.g., when its requests vary between runs, set it to `false` in the
script's `comparison_config` (in a multi-session script, it can also be set for one
session under `comparison_config.sessions.<name>`):

```yaml
comparison_config:
  compare_requests: false
```

The fields of comparisons a script turns off aren't stored in its expected results
files. A comparison runs only when neither the command line nor the script turns it
off. After changing these settings, regenerate the affected expected results with `-u`.

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

The base URL is replaced only where it's a URL to the same Inferno: where it's
followed by `/`, `?`, `#`, or the end of the URL (whitespace, a quote or bracket, or
punctuation such as a sentence-ending `.` or `:`). This includes its URL-encoded
form, e.g., in a `redirect_uri` value. It isn't replaced within a different host,
port, or path: with a base URL of `http://localhost:4567`, `http://localhost:45678`
and `http://localhost:4567.example.com` are left as is, as is `.../suites.json`
when the base URL ends in `/suites`. It also isn't replaced in a different case
(`HTTP://LOCALHOST:4567`), with JSON-escaped slashes (`http:\/\/localhost:4567`),
without its scheme (`localhost:4567`), or when URL-encoded twice. Add rules for
these to a script's `normalized_strings` if its results need them.

Set `comparison_config.default_normalizations: false` in a script to skip steps 2
and 4 and compare those values exactly.

Expected results are stored already normalized, so after adding, changing, or
removing a rule (or renaming a session), regenerate the affected expected results
with `-u` and review the diff.

The standalone `inferno session compare -f` command applies the default
normalizations (steps 2 and 4) for the Inferno given with `-I` (or the default
base URL), but it doesn't know the script's sessions or its `normalized_strings`.
Compare files that contain `<NAME.session_id>` placeholders or depend on the
script's rules by running the script.

```
bundle exec inferno execute_script -u execution_scripts/path/to/script.yaml
```

## Common Normalizations

Only values that change on every run and are unlikely to be mistaken for anything
else are normalized by default. Other values often change between runs too, but
whether they do depends on the test kit, and normalizing a value that doesn't vary
hides real differences (e.g., a test returning the wrong resource id). Add rules
for these to a script's `comparison_config.normalized_strings` when its results
need them:

```yaml
comparison_config:
  normalized_strings:
    # UUIDs. Use only if the script's UUIDs are generated on each run: fixed
    # UUIDs, such as resource ids from fixtures, should usually be compared.
    - pattern: '/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i'
      replacement: '<UUID>'
    # JWTs, which usually contain issued-at and expiration times. The signature
    # segment is empty for unsigned (alg: none) tokens.
    - pattern: '/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*/'
      replacement: '<JWT>'
    # OAuth authorization codes and state values in query strings, keeping the
    # parameter name (\1 is the text matched by the parenthesized group).
    - pattern: '/\b(state|code)=[^&\s"]+/'
      replacement: '\1=<OAUTH_VALUE>'
```

Prefer rules tied to where a value appears, like the OAuth rule above, over rules
for a value's general shape. A rule for any long base64 string, for example, also
matches attachments and other fixed content. Unlike plain strings, regex rules
aren't also applied to the URL-encoded form of what they match.

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
