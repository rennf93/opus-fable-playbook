#!/usr/bin/env bash
# UserPromptSubmit: <=40-token doctrine nudge; question-shape heuristic.
set -u
INPUT="$(cat)" || exit 0
PROMPT="$(printf '%s' "$INPUT" | python3 -c \
  'import json,sys; print(json.load(sys.stdin).get("prompt",""))' 2>/dev/null || true)"
[ -z "$PROMPT" ] && exit 0
case "$PROMPT" in /*) exit 0 ;; esac

TRIMMED="$(printf '%s' "$PROMPT" | sed 's/[[:space:]]*$//')"
FIRST="$(printf '%s' "$PROMPT" | awk '{print tolower($1); exit}')"
LOWER="$(printf '%s' "$TRIMMED" | tr '[:upper:]' '[:lower:]')"
case "$TRIMMED" in *\?) Q=1 ;; *) Q=0 ;; esac
case "$FIRST" in
  why|what|how|is|does|should|can|are|do|where|when|who|which) Q=1 ;;
esac
case "$LOWER" in
  # imperative-investigate-then-report prompts ("run the tests and tell
  # me where this project stands") are assess-only even though they
  # don't start with a question word or end in "?".
  *where*stand*) Q=1 ;;
esac

if [ "${Q:-0}" = "1" ]; then
  printf 'This prompt is question-shaped: deliver your assessment; do not change code unless asked.'
else
  printf 'Fable reminders: lead the final message with the outcome; finish work instead of narrating it; parallelize independent tool calls; delegate broad searches.'
fi
printf '\n'
exit 0
