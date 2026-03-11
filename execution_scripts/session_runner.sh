#!/usr/bin/env bash

# Inferno session CLI orchestration library (requires yq >= 4, jq).
#
# Can be run directly with a YAML config file:
#   bash session_runner.sh my_suite.yaml
#
# Or sourced as a library; call run_session or run_session_from_yaml.
#
# YAML config format:
#
#   session:
#     suite_id: my_suite                       # required
#     preset_id: my-preset                     # optional
#     suite_options:                           # optional
#       option_key: option_value
#     expected_results_file: expected.json     # optional; relative to yaml file
#                                              # default: <yaml_name>_expected.json
#   rules:                                     # ordered; first match wins
#     - status: created                        # created, done, or waiting; running/queued/cancelling handled automatically
#       last_test: ""                          # optional; absent treated as ""; must match exactly (not applicable to created)
#       command: "bundle exec inferno session start_run '{session_id}' -r 5"
#                                              # required; eval used to execute as the next step
#       timeout: 300                           # optional; seconds before execution stops waiting
#
# Template tokens in 'command':
#   {session_id}        – test session id
#   {result_message}    – wait result message (only set when status is waiting)
#   {wait_outputs.KEY}  – value of KEY from the wait_outputs array
#
# Special command values:
#   "END_SCRIPT"       – end execution immediately (explicit terminal rule)
#
# Automatic status handling (no rules needed):
#   running/queued/cancelling        → poll again
#   done (no rule matched)           → warn, run comparison, exit non-zero
#   waiting (no rule matched)        → cancel run and continue polling
#   created (no rule matched)        → warn, run comparison, exit non-zero

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLL_INTERVAL="${POLL_INTERVAL:-5}"              # seconds between status checks
DEFAULT_POLL_TIMEOUT="${DEFAULT_POLL_TIMEOUT:-600}"  # default timeout for poll_until_action

# Default implementation – reads rules from a YAML config file via yq + jq.
# Override by defining next_action_from_status after sourcing this file.
next_action_from_status() {
  local status_json="$1"
  local config_file="${ACTIONS_FILE:-$(dirname "$0")/$(basename "$0" .sh).yaml}"

  if [[ ! -f "$config_file" ]]; then
    printf 'next_action_from_status: config file not found: %s\n' "$config_file" >&2
    return 1
  fi

  local status session_id last_test
  status=$(printf '%s' "$status_json" | jq -r '.status')
  session_id=$(printf '%s' "$status_json" | jq -r '.test_session_id')
  last_test=$(printf '%s' "$status_json" | jq -r '.last_test_executed // ""')

  local rule
  rule=$(yq -o=json "$config_file" | jq \
    --arg status "$status" \
    --arg last_test "$last_test" \
    '[.rules[] | select(
      .status == $status and
      (.last_test // "") == $last_test
    )] | .[0]')

  if [[ -z "$rule" || "$rule" == "null" ]]; then
    # No rule matched – return empty; session_runner applies defaults:
    #   done    → emit UNMATCHED
    #   waiting → cancel run and emit UNMATCHED
    return 0
  fi

  local cmd
  cmd=$(printf '%s' "$rule" | jq -r '.command // empty')

  # No command field – delegate to session_runner (poll again / UNMATCHED / cancel)
  [[ -z "$cmd" ]] && return 0

  # Template substitution
  cmd="${cmd//\{session_id\}/$session_id}"
  local result_message result_message_q
  result_message=$(printf '%s' "$status_json" | jq -r '.wait_result_message // ""')
  result_message_q=$(printf '%q' "$result_message")
  cmd="${cmd//\{result_message\}/$result_message_q}"
  while [[ "$cmd" =~ \{wait_outputs\.([^}]+)\} ]]; do
    local key="${BASH_REMATCH[1]}"
    local value
    value=$(printf '%s' "$status_json" | jq -r --arg key "$key" \
      '.wait_outputs[] | select(.name == $key) | .value')
    cmd="${cmd//\{wait_outputs.$key\}/$value}"
  done

  # Auto-append -I for inferno CLI commands when INFERNO_URL is set
  [[ "$cmd" == *"bundle exec inferno"* && -n "$INFERNO_URL" ]] && \
    cmd+=" -I '$INFERNO_URL'"

  local timeout
  timeout=$(printf '%s' "$rule" | jq -r '.timeout // empty')

  if [[ -n "$timeout" ]]; then
    printf '%s\n%s\n' "$cmd" "$timeout"
  else
    echo "$cmd"
  fi
}

# Poll 'session status' every $POLL_INTERVAL seconds until the run leaves the
# 'running' state. Echoes the command and resolved timeout on separate lines
# and exits 0 on a recognized non-running state; exits 1 on timeout or error.
# Set INFERNO_URL to pass -I to every status call.
#
# Output (two lines for non-UNMATCHED results):
#   UNMATCHED            – no rule matched; session ended unexpectedly
#   <command>\n<timeout> – command to eval and timeout (seconds) for next call
#
# Usage: poll_until_action SESSION_ID [TIMEOUT_SECONDS]
#
# Mirrors pause_until_waiting / pause_until_done in session_controller.rb:
# call once after start_run; eval the result to handle a waiting step,
# or check for UNMATCHED to detect an unexpected terminal state.
poll_until_action() {
  local session_id="$1"
  local timeout="${2:-$DEFAULT_POLL_TIMEOUT}"
  local elapsed=0

  while (( elapsed < timeout )); do
    local status_json run_status
    status_json=$(bundle exec inferno session status "$session_id" \
      ${INFERNO_URL:+-I "$INFERNO_URL"})
    run_status=$(printf '%s' "$status_json" | jq -r '.status')

    # running/queued/cancelling → poll again automatically
    if [[ "$run_status" == "running" || "$run_status" == "queued" || "$run_status" == "cancelling" ]]; then
      sleep "$POLL_INTERVAL"
      (( elapsed += POLL_INTERVAL ))
      continue
    fi

    local action
    action=$(next_action_from_status "$status_json") || return 1

    if [[ -n "$action" ]]; then
      local cmd next_timeout
      cmd=$(printf '%s' "$action" | head -1)
      next_timeout=$(printf '%s' "$action" | sed -n '2p')
      printf '%s\n%s\n' "$cmd" "${next_timeout:-$DEFAULT_POLL_TIMEOUT}"
      return 0
    fi

    if [[ "$run_status" == "done" || "$run_status" == "created" ]]; then
      local done_last_test
      done_last_test=$(printf '%s' "$status_json" | jq -r '.last_test_executed // ""')
      printf 'No rule matched for status=%s last_test=%s; ending session\n' \
        "$run_status" "$done_last_test" >&2
      echo "UNMATCHED"
      return 0
    fi

    if [[ "$run_status" == "waiting" ]]; then
      local wait_last_test
      wait_last_test=$(printf '%s' "$status_json" | jq -r '.last_test_executed // ""')
      printf 'Unhandled wait state (last_test=%s); cancelling current run for session %s\n' \
        "$wait_last_test" "$session_id" >&2
      bundle exec inferno session cancel_run "$session_id" \
        ${INFERNO_URL:+-I "$INFERNO_URL"} >&2 || return 1
      sleep "$POLL_INTERVAL"
      (( elapsed += POLL_INTERVAL ))
      continue
    fi

    printf 'poll_until_action: unexpected status %s for session %s\n' "$run_status" "$session_id" >&2
    return 1
  done

  printf 'poll_until_action: timed out after %ds (session %s)\n' \
    "$timeout" "$session_id" >&2
  return 1
}

# Create a session and run the poll loop until all runs are done.
# Set INFERNO_URL to pass -I to every API call.
#
# Usage: run_session SUITE_ID [-p PRESET_ID] [-o KEY:VAL ...] [-f EXPECTED_RESULTS_FILE]
#   SUITE_ID                – suite id passed to 'session create'
#   -p                      – preset id to apply when creating the session
#   -o KEY:VAL              – suite option(s); repeat KEY:VAL pairs as needed
#   -f EXPECTED_RESULTS_FILE – path to expected results file for 'session compare'
#                             (default: <script_name>_expected.json next to the calling script)
run_session() {
  local suite_id="$1"
  shift

  local preset_id=""
  local suite_opts_args=()
  local expected_results_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p) shift; preset_id="$1"; shift ;;
      -f) shift; expected_results_file="$1"; shift ;;
      -o)
        shift
        while [[ $# -gt 0 && "$1" == *:* ]]; do
          suite_opts_args+=("$1"); shift
        done
        ;;
      *) printf 'run_session: unknown argument: %s\n' "$1" >&2; return 1 ;;
    esac
  done

  if [[ -z "$expected_results_file" ]]; then
    expected_results_file="$(dirname "$0")/$(basename "$0" .sh)_expected.json"
  fi

  local create_cmd=(bundle exec inferno session create "$suite_id")
  [[ -n "$preset_id" ]] && create_cmd+=(-p "$preset_id")
  [[ ${#suite_opts_args[@]} -gt 0 ]] && create_cmd+=(-o "${suite_opts_args[@]}")
  [[ -n "$INFERNO_URL" ]] && create_cmd+=(-I "$INFERNO_URL")

  echo "Creating '$suite_id' session..."
  local session_json session_id
  if ! session_json=$("${create_cmd[@]}"); then
    printf 'run_session: session create failed for suite %s\n' "$suite_id" >&2
    [[ -n "$session_json" ]] && printf '%s\n' "$session_json" >&2
    return 1
  fi
  session_id=$(printf '%s' "$session_json" | jq -r '.id')
  if [[ -z "$session_id" || "$session_id" == "null" ]]; then
    printf 'run_session: session create returned no id (suite %s)\n' "$suite_id" >&2
    return 1
  fi
  echo "Session created: $session_id"

  local timeout="$DEFAULT_POLL_TIMEOUT"
  local unmatched_done=false
  while true; do
    local output cmd
    output=$(poll_until_action "$session_id" "$timeout") || return 1
    cmd=$(printf '%s' "$output" | head -1)
    if [[ "$cmd" == "UNMATCHED" ]]; then
      unmatched_done=true
      break
    fi
    if [[ "$cmd" == "END_SCRIPT" ]]; then
      break
    fi
    timeout=$(printf '%s' "$output" | sed -n '2p')
    echo "Executing: $cmd"
    local cmd_output
    if ! cmd_output=$(eval "$cmd"); then
      printf '%s\n' "$cmd_output" >&2
      return 1
    fi
  done

  echo "All runs complete."

  local compare_result=0
  if [[ -f "$expected_results_file" ]]; then
    bundle exec inferno session compare "$session_id" \
      -f "$expected_results_file" \
      ${INFERNO_URL:+-I "$INFERNO_URL"} || compare_result=$?
  elif [[ "$unmatched_done" == "false" ]]; then
    echo "Expected results file not found; writing results to '$expected_results_file'..."
    bundle exec inferno session results "$session_id" \
      ${INFERNO_URL:+-I "$INFERNO_URL"} > "$expected_results_file"
  fi

  [[ "$unmatched_done" == "true" ]] && return 1
  return $compare_result
}

# Run a session defined entirely by a YAML config file (session config + rules).
# Set INFERNO_URL to pass -I to every API call.
#
# Usage: run_session_from_yaml YAML_FILE
run_session_from_yaml() {
  local yaml_file="$1"

  if [[ -z "$yaml_file" ]]; then
    printf 'Usage: run_session_from_yaml <yaml_file>\n' >&2
    return 1
  fi

  if [[ ! -f "$yaml_file" ]]; then
    printf 'run_session_from_yaml: file not found: %s\n' "$yaml_file" >&2
    return 1
  fi

  # Resolve to absolute path so relative paths inside the YAML resolve correctly
  yaml_file="$(cd "$(dirname "$yaml_file")" && pwd)/$(basename "$yaml_file")"
  export ACTIONS_FILE="$yaml_file"

  local session_config
  session_config=$(yq -o=json "$yaml_file" | jq '.session')

  local suite_id
  suite_id=$(printf '%s' "$session_config" | jq -r '.suite_id')
  if [[ -z "$suite_id" || "$suite_id" == "null" ]]; then
    printf 'run_session_from_yaml: session.suite_id is required in %s\n' "$yaml_file" >&2
    return 1
  fi

  local run_args=("$suite_id")

  local preset_id
  preset_id=$(printf '%s' "$session_config" | jq -r '.preset_id // empty')
  [[ -n "$preset_id" ]] && run_args+=(-p "$preset_id")

  # Suite options: convert YAML map to KEY:VALUE args
  local opts_array=()
  while IFS= read -r opt; do
    [[ -n "$opt" ]] && opts_array+=("$opt")
  done < <(printf '%s' "$session_config" | \
    jq -r '.suite_options // {} | to_entries[] | "\(.key):\(.value)"')
  [[ ${#opts_array[@]} -gt 0 ]] && run_args+=(-o "${opts_array[@]}")

  # Expected results file; relative paths are resolved relative to the yaml file
  local expected_results_file
  expected_results_file=$(printf '%s' "$session_config" | jq -r '.expected_results_file // empty')
  if [[ -n "$expected_results_file" ]]; then
    [[ "$expected_results_file" != /* ]] && \
      expected_results_file="$(dirname "$yaml_file")/$expected_results_file"
  else
    expected_results_file="$(dirname "$yaml_file")/$(basename "$yaml_file" .yaml)_expected.json"
  fi
  run_args+=(-f "$expected_results_file")

  run_session "${run_args[@]}"
}

# When executed directly (not sourced), run the YAML file passed as the first argument
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_session_from_yaml "$1" || exit 1
fi
