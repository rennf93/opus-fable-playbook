#!/usr/bin/env bash
# Stop/SubagentStop gate: block turn endings that promise instead of do.
# Usage: stop-gate.sh [subagent]   Fail-open: any internal error => exit 0.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=hooks/lib/telemetry.sh
. "$DIR/lib/telemetry.sh"

INPUT="$(cat)" || exit 0
py() { printf '%s' "$INPUT" | python3 -c "$1" 2>/dev/null || true; }

ACTIVE="$(py 'import json,sys; print(json.load(sys.stdin).get("stop_hook_active", False))')"
[ "$ACTIVE" = "True" ] && exit 0

SESSION="$(py 'import json,sys; print(json.load(sys.stdin).get("session_id","unknown"))')"
LAST="$(printf '%s' "$INPUT" | python3 "$DIR/lib/last_message.py" 2>/dev/null)" || exit 0
[ -z "$LAST" ] && exit 0

# Final paragraph = last blank-line-separated block (awk paragraph mode).
FINAL="$(printf '%s' "$LAST" | awk -v RS='' 'END{print}')"
[ -z "$FINAL" ] && exit 0

VERBS='(start|begin|proceed|continue|create|implement|write|update|fix|add|run|check|investigate|work|make|set|move|look|open|draft|explore|apply|push|refactor|clean|test)'
MATCH=""
printf '%s' "$FINAL" | grep -qiE "(^|[^a-z])i('|’)?ll (now |then |next |also |go ahead and )?$VERBS" && MATCH="ill-promise"
[ -z "$MATCH" ] && printf '%s' "$FINAL" | grep -qiE "(^|[^a-z])i will (now |then |next |also )?$VERBS" && MATCH="i-will"
[ -z "$MATCH" ] && printf '%s' "$FINAL" | grep -qiE "(^|[[:space:]])next steps?:" && MATCH="next-steps"
[ -z "$MATCH" ] && printf '%s' "$FINAL" | grep -qiE "let me know (if|when|whether|what|which|and)" && MATCH="let-me-know"
[ -z "$MATCH" ] && printf '%s' "$FINAL" | grep -qiE "would you like me to" && MATCH="would-you-like"
[ -z "$MATCH" ] && printf '%s' "$FINAL" | grep -qiE "(^|[^a-z])shall i " && MATCH="shall-i"
# Golden calibration 2026-07-02: bare "want me to " blocked real Fable endings
# (assess-only tasks ending "want me to apply the fix?" — a genuine decision
# question). Anchor to continuation verbs so only in-scope deferral blocks.
[ -z "$MATCH" ] && printf '%s' "$FINAL" | grep -qiE "(^|[^a-z])want me to (continue|proceed|keep going|finish|do the rest)" && MATCH="want-me-to"

MODE="${1:-main}"

# Opt-in LLM judge tier (main mode only, only when tier 1 found nothing).
if [ -z "$MATCH" ] && [ "$MODE" = "main" ] && [ "${FABLE_STOP_JUDGE:-0}" = "1" ] \
   && command -v claude >/dev/null 2>&1; then
  # --bare requires API-key auth and breaks OAuth-only machines (Task 15 finding); inherit session auth instead — plugin contamination is acceptable for a 10-word verdict.
  VERDICT="$(printf 'Does this assistant turn-ending violate the rule "finish the work instead of promising it; do not seek permission for reversible in-scope actions"? Reply with exactly YES or NO.\n\n---\n%s' "$FINAL" \
    | claude -p --model "${FABLE_STOP_JUDGE_MODEL:-claude-haiku-4-5-20251001}" 2>/dev/null | tr -d '[:space:]')"
  [ "$VERDICT" = "YES" ] && MATCH="judge"
fi

[ -z "$MATCH" ] && exit 0

if [ "$MODE" = "subagent" ]; then
  fable_telemetry "stop-gate-subagent" "$MATCH" "$SESSION"
  REASON="Fable subagent discipline: your final message is your return value. Return your findings now — conclusions with evidence, not intentions, plans, or offers."
else
  fable_telemetry "stop-gate" "$MATCH" "$SESSION"
  REASON="Fable turn discipline: your last paragraph promises or proposes work instead of doing it. Do that work now — retry errors and gather missing information yourself. If you are genuinely blocked on something only the user can provide, state that blocking question plainly and stop."
fi

printf '{"decision": "block", "reason": "%s"}' "$REASON"
exit 0
