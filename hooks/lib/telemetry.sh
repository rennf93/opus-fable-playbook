#!/usr/bin/env bash
# fable_telemetry HOOK PATTERN [SESSION_ID] — append one JSONL event.
# Fail-open: never returns nonzero, never prints.
fable_telemetry() {
  [ "${FABLE_TELEMETRY:-1}" = "0" ] && return 0
  _ft_file="${FABLE_TELEMETRY_FILE:-${HOME:-/tmp}/.claude/fable-mode/telemetry.jsonl}"
  {
    mkdir -p "$(dirname "$_ft_file")" &&
    printf '{"ts":"%s","hook":"%s","pattern":"%s","session_id":"%s"}\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-unknown}" "${2:-unknown}" \
      "${3:-unknown}" >> "$_ft_file"
  } 2>/dev/null || true
  return 0
}
