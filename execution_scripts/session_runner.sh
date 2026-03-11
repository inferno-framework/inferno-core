#!/usr/bin/env bash

# Shared library for inferno session CLI orchestration.
# Source this file, then define next_action_from_status for your execution path.
#
# next_action_from_status STATUS_JSON must echo one of:
#   (empty)              – run still in progress; poll again
#   DONE                 – all runs complete
#   <command>            – shell command to eval; next poll uses default timeout
#   <command>\n<timeout> – shell command to eval; next poll uses timeout (seconds)

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLL_INTERVAL="${POLL_INTERVAL:-5}"              # seconds between status checks
DEFAULT_POLL_TIMEOUT="${DEFAULT_POLL_TIMEOUT:-600}"  # default timeout for poll_until_action

# Poll 'session status' every $POLL_INTERVAL seconds until the run leaves the
# 'running' state. Echoes the command and resolved timeout on separate lines
# and exits 0 on a recognized non-running state; exits 1 on timeout or error.
# Set INFERNO_URL to pass -I to every status call.
#
# Output (two lines for non-DONE results):
#   DONE                 – all runs complete
#   <command>\n<timeout> – command to eval and timeout (seconds) for next call
#
# Usage: poll_until_action SESSION_ID [TIMEOUT_SECONDS]
#
# Mirrors pause_until_waiting / pause_until_done in session_controller.rb:
# call once after start_run; eval the result to handle a waiting step,
# or check for DONE to move on to the next group.
poll_until_action() {
  local session_id="$1"
  local timeout="${2:-$DEFAULT_POLL_TIMEOUT}"
  local elapsed=0

  while (( elapsed < timeout )); do
    local status_json action
    status_json=$(bundle exec inferno session status "$session_id" \
      ${INFERNO_URL:+-I "$INFERNO_URL"})
    action=$(next_action_from_status "$status_json") || return 1

    if [[ -n "$action" ]]; then
      local cmd next_timeout
      cmd=$(printf '%s' "$action" | head -1)
      next_timeout=$(printf '%s' "$action" | sed -n '2p')
      printf '%s\n%s\n' "$cmd" "${next_timeout:-$DEFAULT_POLL_TIMEOUT}"
      return 0
    fi

    local run_status
    run_status=$(printf '%s' "$status_json" | jq -r '.status')

    if [[ "$run_status" == "done" ]]; then
      echo "DONE"
      return 0
    fi

    if [[ "$run_status" == "waiting" ]]; then
      printf 'Unhandled wait state; cancelling current run for session %s\n' "$session_id" >&2
      bundle exec inferno session cancel_run "$session_id" \
        ${INFERNO_URL:+-I "$INFERNO_URL"} >&2 || return 1
      echo "DONE"
      return 0
    fi

    sleep "$POLL_INTERVAL"
    (( elapsed += POLL_INTERVAL ))
  done

  printf 'poll_until_action: timed out after %ds (session %s)\n' \
    "$timeout" "$session_id" >&2
  return 1
}

# Create a session and run the poll loop until all runs are done.
# Caller must define next_action_from_status before calling this.
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
  session_json=$("${create_cmd[@]}") || return 1
  session_id=$(printf '%s' "$session_json" | jq -r '.id')
  echo "Session created: $session_id"

  local timeout="$DEFAULT_POLL_TIMEOUT"
  while true; do
    local output cmd
    output=$(poll_until_action "$session_id" "$timeout") || return 1
    cmd=$(printf '%s' "$output" | head -1)
    if [[ "$cmd" == "DONE" ]]; then
      echo "All runs complete."
      break
    fi
    timeout=$(printf '%s' "$output" | sed -n '2p')
    echo "Executing: $cmd"
    eval "$cmd" || return 1
  done

  if [[ -f "$expected_results_file" ]]; then
    bundle exec inferno session compare "$session_id" \
      -f "$expected_results_file" \
      ${INFERNO_URL:+-I "$INFERNO_URL"}
  else
    echo "Expected results file not found; writing results to '$expected_results_file'..."
    bundle exec inferno session results "$session_id" \
      ${INFERNO_URL:+-I "$INFERNO_URL"} > "$expected_results_file"
  fi
}
