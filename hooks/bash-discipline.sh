#!/usr/bin/env bash
# PreToolUse[Bash]: deny pure shell file-reads; dedicated tools exist.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=hooks/lib/telemetry.sh
. "$DIR/lib/telemetry.sh"

INPUT="$(cat)" || exit 0
CMD="$(printf '%s' "$INPUT" | python3 -c \
  'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' \
  2>/dev/null || true)"
[ -z "$CMD" ] && exit 0

# Pipelines, compounds, redirects, heredocs are legitimate — allow.
printf '%s' "$CMD" | grep -qE '\||&&|;|>|<<' && exit 0

DENY=0
printf '%s' "$CMD" | grep -qE '^[[:space:]]*(cat|head|tail|less|more)[[:space:]]' && DENY=1
printf '%s' "$CMD" | grep -qE '^[[:space:]]*sed[[:space:]]+-n[[:space:]]' && DENY=1
[ "$DENY" -eq 0 ] && exit 0

SESSION="$(printf '%s' "$INPUT" | python3 -c \
  'import json,sys; print(json.load(sys.stdin).get("session_id","unknown"))' \
  2>/dev/null || true)"
fable_telemetry "bash-discipline" "shell-read" "$SESSION"

cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "Fable tool discipline: use the dedicated Read/Grep tools instead of shell file-reads (cat/head/tail/less/sed -n). Read is paginated and line-numbered; Grep searches without loading whole files."}}
JSON
exit 0
