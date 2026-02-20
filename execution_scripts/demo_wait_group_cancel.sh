#!/usr/bin/env bash

# shellcheck source=session_runner.sh
source "$(dirname "${BASH_SOURCE[0]}")/session_runner.sh"

# Given the JSON output of 'bundle exec inferno session status SESSION_ID',
# echoes the next action and exits 0. Exits 1 and writes to stderr on
# unrecognized states.
#
# Output:
#   (empty)              – run still in progress; caller should sleep and poll again
#   DONE                 – run completed with no further action
#   <command>            – shell command to eval; next poll uses default timeout
#   <command>\n<timeout> – shell command to eval; next poll uses timeout (seconds)
next_action_from_status() {
  local status_json="$1"

  local status session_id last_test
  status=$(printf '%s' "$status_json" | jq -r '.status')
  session_id=$(printf '%s' "$status_json" | jq -r '.test_session_id')
  last_test=$(printf '%s' "$status_json" | jq -r '.last_test_executed // ""')

  case "$status" in

    running|queued|cancelling)
      return 0
      ;;

    waiting)
      return 0
      ;;

    done)
      case "$last_test" in
        "")
          local cmd="bundle exec inferno session start_run '$session_id' -r 5"
          [[ -n "$INFERNO_URL" ]] && cmd+=" -I '$INFERNO_URL'"
          echo "$cmd"
          ;;
        *)
          # No command to return; session_runner will emit DONE.
          return 0
          ;;
      esac
      ;;

    *)
      printf 'Unrecognized status: %s\n' "$status" >&2
      return 1
      ;;

  esac
}

# === Main ===

run_session "demo" || exit 1
