#!/usr/bin/env bash
# fable-mode test runner. No frameworks; bash 3.2 compatible.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$ROOT/hooks"
FIX="$ROOT/tests/fixtures"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export FABLE_TELEMETRY_FILE="$TMP/telemetry.jsonl"
PASS=0
FAIL=0

# check NAME STDIN_FILE EXPECT script args...
check() {
  name="$1"; stdin="$2"; expect="$3"; shift 3
  out="$("$@" < "$stdin" 2>/dev/null)"; code=$?
  ok=0
  case "$expect" in
    block)   [ $code -eq 0 ] && printf '%s' "$out" | grep -q '"decision": *"block"' && ok=1 ;;
    deny)    [ $code -eq 0 ] && printf '%s' "$out" | grep -q '"permissionDecision": *"deny"' && ok=1 ;;
    context) [ $code -eq 0 ] && [ -n "$out" ] && ok=1 ;;
    empty)   [ $code -eq 0 ] && [ -z "$out" ] && ok=1 ;;
  esac
  if [ $ok -eq 1 ]; then PASS=$((PASS+1)); echo "PASS: $name";
  else FAIL=$((FAIL+1)); echo "FAIL: $name (exit=$code out=${out:0:120})"; fi
}

# stop_stdin TRANSCRIPT_FIXTURE [ACTIVE] -> path to stdin json in $TMP
stop_stdin() {
  printf '{"session_id":"test","stop_hook_active":%s,"transcript_path":"%s"}' \
    "${2:-false}" "$1" > "$TMP/stdin.json"
  echo "$TMP/stdin.json"
}

echo "== structure =="
python3 "$ROOT/tests/check_structure.py" || FAIL=$((FAIL+1))

echo "== last_message.py =="
s="$(stop_stdin "$FIX/transcript-promise.jsonl")"
out="$(python3 "$HOOKS/lib/last_message.py" < "$s")"
if printf '%s' "$out" | grep -q "update the xml parser"; then
  PASS=$((PASS+1)); echo "PASS: extracts last assistant text"
else FAIL=$((FAIL+1)); echo "FAIL: extracts last assistant text"; fi

s="$(stop_stdin "$FIX/transcript-sidechain.jsonl")"
out="$(python3 "$HOOKS/lib/last_message.py" < "$s")"
if printf '%s' "$out" | grep -q "migrated and verified" && ! printf '%s' "$out" | grep -q "begin scanning"; then
  PASS=$((PASS+1)); echo "PASS: skips sidechain lines"
else FAIL=$((FAIL+1)); echo "FAIL: skips sidechain lines"; fi

printf '{"transcript_path":"/nonexistent"}' > "$TMP/bad.json"
out="$(python3 "$HOOKS/lib/last_message.py" < "$TMP/bad.json")"; code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then
  PASS=$((PASS+1)); echo "PASS: fails open on missing transcript"
else FAIL=$((FAIL+1)); echo "FAIL: fails open on missing transcript"; fi

echo "== stop-gate =="
check "blocks promise ending"      "$(stop_stdin "$FIX/transcript-promise.jsonl")"   block "$HOOKS/stop-gate.sh"
check "blocks let-me-know ending"  "$(stop_stdin "$FIX/transcript-letmeknow.jsonl")" block "$HOOKS/stop-gate.sh"
check "allows decision question"   "$(stop_stdin "$FIX/transcript-question.jsonl")"  empty "$HOOKS/stop-gate.sh"
check "allows clean outcome"       "$(stop_stdin "$FIX/transcript-clean.jsonl")"     empty "$HOOKS/stop-gate.sh"
check "allows when stop_hook_active" "$(stop_stdin "$FIX/transcript-promise.jsonl" true)" empty "$HOOKS/stop-gate.sh"
check "subagent mode blocks promise" "$(stop_stdin "$FIX/transcript-promise.jsonl")" block "$HOOKS/stop-gate.sh" subagent
printf 'not json' > "$TMP/garbage.json"
check "fails open on garbage stdin" "$TMP/garbage.json" empty "$HOOKS/stop-gate.sh"
check "blocks without HOME set" "$(stop_stdin "$FIX/transcript-promise.jsonl")" block env -u HOME -u FABLE_TELEMETRY_FILE "$HOOKS/stop-gate.sh"

if grep -q '"hook":"stop-gate"' "$FABLE_TELEMETRY_FILE" 2>/dev/null; then
  PASS=$((PASS+1)); echo "PASS: telemetry line written"
else FAIL=$((FAIL+1)); echo "FAIL: telemetry line written"; fi

echo "== bash-discipline =="
bd_stdin() { printf '{"session_id":"test","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" > "$TMP/bd.json"; echo "$TMP/bd.json"; }
check "denies cat file"          "$(bd_stdin 'cat src/app.py')"            deny  "$HOOKS/bash-discipline.sh"
check "denies head -n"           "$(bd_stdin 'head -n 50 README.md')"      deny  "$HOOKS/bash-discipline.sh"
check "denies sed -n range"      "$(bd_stdin "sed -n '10,20p' src/app.py")" deny "$HOOKS/bash-discipline.sh"
check "allows cat into pipe"     "$(bd_stdin 'cat data.csv | wc -l')"      empty "$HOOKS/bash-discipline.sh"
check "allows redirect"          "$(bd_stdin 'cat a.txt b.txt > merged.txt')" empty "$HOOKS/bash-discipline.sh"
check "allows unrelated command" "$(bd_stdin 'make test')"                 empty "$HOOKS/bash-discipline.sh"
check "fails open on garbage"    "$TMP/garbage.json"                       empty "$HOOKS/bash-discipline.sh"

echo "== honesty-nudge =="
hn_stdin() { printf '{"session_id":"test","tool_name":"Bash","tool_response":{"stdout":%s,"stderr":""}}' "$1" > "$TMP/hn.json"; echo "$TMP/hn.json"; }
check "fires on pytest FAILED"   "$(hn_stdin '"FAILED tests/test_x.py::test_a - AssertionError"')" context "$HOOKS/honesty-nudge.sh"
check "fires on go FAIL"         "$(hn_stdin '"--- FAIL: TestParse (0.00s)"')"                     context "$HOOKS/honesty-nudge.sh"
check "fires on cargo FAILED"    "$(hn_stdin '"test result: FAILED. 1 passed; 2 failed"')"          context "$HOOKS/honesty-nudge.sh"
check "fires on traceback"       "$(hn_stdin '"Traceback (most recent call last):\n  boom"')"       context "$HOOKS/honesty-nudge.sh"
check "silent on passing output" "$(hn_stdin '"42 passed in 3.1s"')"                                empty   "$HOOKS/honesty-nudge.sh"
check "silent on garbage"        "$TMP/garbage.json"                                                empty   "$HOOKS/honesty-nudge.sh"

echo ""
echo "== results: $PASS passed, $FAIL failed =="
[ $FAIL -eq 0 ]
