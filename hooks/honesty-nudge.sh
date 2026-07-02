#!/usr/bin/env bash
# PostToolUse[Bash]: when output shows failures, nudge verbatim reporting.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=hooks/lib/telemetry.sh
. "$DIR/lib/telemetry.sh"

INPUT="$(cat)" || exit 0
RESP="$(printf '%s' "$INPUT" | python3 -c \
  'import json,sys; print(json.dumps(json.load(sys.stdin).get("tool_response","")))' \
  2>/dev/null || true)"
[ -z "$RESP" ] || [ "$RESP" = '""' ] && exit 0

HIT=0
printf '%s' "$RESP" | grep -qE 'FAILED |= FAILURES =|test result: FAILED|--- FAIL|AssertionError|Traceback \(most recent call last\)' && HIT=1
printf '%s' "$RESP" | grep -qE 'Tests:[^"]*failed' && HIT=1
[ "$HIT" -eq 0 ] && exit 0

SESSION="$(printf '%s' "$INPUT" | python3 -c \
  'import json,sys; print(json.load(sys.stdin).get("session_id","unknown"))' \
  2>/dev/null || true)"
fable_telemetry "honesty-nudge" "failure-output" "$SESSION"

cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "A command just reported failures. Fable honesty rule: report this outcome verbatim (the actual failing output) in your final message; do not summarize it as mostly-working or claim success."}}
JSON
exit 0
