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
check "blocks i-will ending"         "$(stop_stdin "$FIX/transcript-iwill.jsonl")"        block "$HOOKS/stop-gate.sh"
check "blocks next-steps ending"     "$(stop_stdin "$FIX/transcript-nextsteps.jsonl")"    block "$HOOKS/stop-gate.sh"
check "blocks would-you-like ending" "$(stop_stdin "$FIX/transcript-wouldyoulike.jsonl")" block "$HOOKS/stop-gate.sh"
check "blocks shall-i ending"        "$(stop_stdin "$FIX/transcript-shalli.jsonl")"       block "$HOOKS/stop-gate.sh"
check "blocks want-me-to ending"     "$(stop_stdin "$FIX/transcript-wantmeto.jsonl")"     block "$HOOKS/stop-gate.sh"
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

echo "== session/prompt/precompact =="
printf '{"session_id":"test","source":"startup"}' > "$TMP/ss.json"
check "session-start emits card" "$TMP/ss.json" context "$HOOKS/session-start.sh"
out="$("$HOOKS/session-start.sh" < "$TMP/ss.json" 2>/dev/null)"
if printf '%s' "$out" | grep -q "fable-doctrine-card"; then
  PASS=$((PASS+1)); echo "PASS: card content present"
else FAIL=$((FAIL+1)); echo "FAIL: card content present"; fi

pn_stdin() { printf '{"session_id":"test","prompt":%s}' "$1" > "$TMP/pn.json"; echo "$TMP/pn.json"; }
check "prompt nudge on statement"  "$(pn_stdin '"refactor the auth module"')" context "$HOOKS/prompt-nudge.sh"
check "skips slash commands"       "$(pn_stdin '"/fable-status"')"            empty   "$HOOKS/prompt-nudge.sh"
out="$("$HOOKS/prompt-nudge.sh" < "$(pn_stdin '"why is the deploy failing?"')" 2>/dev/null)"
if printf '%s' "$out" | grep -q "question-shaped"; then
  PASS=$((PASS+1)); echo "PASS: question heuristic fires"
else FAIL=$((FAIL+1)); echo "FAIL: question heuristic fires"; fi
out="$("$HOOKS/prompt-nudge.sh" < "$(pn_stdin '"add a retry to the client"')" 2>/dev/null)"
if printf '%s' "$out" | grep -q "question-shaped"; then
  FAIL=$((FAIL+1)); echo "FAIL: question heuristic silent on imperative"
else PASS=$((PASS+1)); echo "PASS: question heuristic silent on imperative"; fi

printf '{"session_id":"test","trigger":"auto"}' > "$TMP/pc.json"
check "precompact emits guidance" "$TMP/pc.json" context "$HOOKS/precompact.sh"

echo "== eval scripts =="
export FABLE_EVAL_DRY_RUN=1
out="$("$ROOT/evals/run-probe.sh" "$ROOT/evals/probes/01-simple-question.md" baseline "$TMP" 2>/dev/null)"
if printf '%s' "$out" | grep -q -- "--settings" && printf '%s' "$out" | grep -q "\.iso\.settings\.json" && printf '%s' "$out" | grep -q "claude-opus-4-8"; then
  PASS=$((PASS+1)); echo "PASS: baseline dry-run uses isolation settings + opus"
else FAIL=$((FAIL+1)); echo "FAIL: baseline dry-run uses isolation settings + opus"; fi
out="$("$ROOT/evals/run-probe.sh" "$ROOT/evals/probes/01-simple-question.md" fable "$TMP" 2>/dev/null)"
if printf '%s' "$out" | grep -q -- "--plugin-dir" && printf '%s' "$out" | grep -q "\.iso\.settings\.json"; then
  PASS=$((PASS+1)); echo "PASS: fable dry-run loads plugin + isolation settings"
else FAIL=$((FAIL+1)); echo "FAIL: fable dry-run loads plugin + isolation settings"; fi
unset FABLE_EVAL_DRY_RUN

out="$(python3 "$ROOT/evals/lib/isolation.py" --merge /nonexistent.json 2>/dev/null)"
if printf '%s' "$out" | grep -q '"enabledPlugins"'; then
  PASS=$((PASS+1)); echo "PASS: isolation keeps disable map on merge error"
else FAIL=$((FAIL+1)); echo "FAIL: isolation keeps disable map on merge error"; fi

printf '{"result":"{\\"scores\\":{\\"outcome_first\\":2,\\"no_burial\\":2,\\"turn_completion\\":1,\\"autonomy_calibration\\":2,\\"honesty\\":2,\\"delegation_parallelism\\":1,\\"tool_discipline\\":2,\\"code_comment_discipline\\":2},\\"closer_to_golden\\":\\"golden\\",\\"rationale\\":\\"mock\\"}"}' > "$TMP/mockout.json"
printf '{"result":"candidate final text"}' > "$TMP/cand.json"
printf '{"result":"golden final text"}' > "$TMP/gold.json"
export FABLE_JUDGE_CMD="$ROOT/tests/fixtures/mock-judge.sh $TMP/mockout.json"
if "$ROOT/evals/judge.sh" "$ROOT/evals/probes/01-simple-question.md" "$TMP/cand.json" "$TMP/gold.json" "$TMP" >/dev/null 2>&1 \
   && grep -q '"turn_completion": 1' "$TMP/01-simple-question.cand.verdict.json"; then
  PASS=$((PASS+1)); echo "PASS: judge parses mock verdict"
else FAIL=$((FAIL+1)); echo "FAIL: judge parses mock verdict"; fi
unset FABLE_JUDGE_CMD
if "$ROOT/evals/report.sh" "$TMP" 2>/dev/null | grep -q "turn_completion"; then
  PASS=$((PASS+1)); echo "PASS: report aggregates verdicts"
else FAIL=$((FAIL+1)); echo "FAIL: report aggregates verdicts"; fi

echo "== shell syntax smoke =="
for f in "$HOOKS"/*.sh "$HOOKS"/lib/*.sh; do
  if bash -n "$f" 2>/dev/null; then PASS=$((PASS+1)); echo "PASS: bash -n $(basename "$f")";
  else FAIL=$((FAIL+1)); echo "FAIL: bash -n $(basename "$f")"; fi
done

echo "== golden calibration (stop-gate false positives) =="
GOLD_DIR="$ROOT/evals/golden"
if ls "$GOLD_DIR"/*.golden.json >/dev/null 2>&1; then
  for g in "$GOLD_DIR"/*.golden.json; do
    python3 -c '
import json, sys
r = json.load(open(sys.argv[1])).get("result", "")
line = json.dumps({"type": "assistant", "isSidechain": False,
                   "message": {"content": [{"type": "text", "text": r}]}})
open(sys.argv[2], "w").write(line + "\n")' "$g" "$TMP/gt.jsonl"
    check "no false positive: $(basename "$g")" "$(stop_stdin "$TMP/gt.jsonl")" empty "$HOOKS/stop-gate.sh"
  done
else
  echo "SKIP: no goldens yet (generate in Task 15)"
fi

echo ""
echo "== results: $PASS passed, $FAIL failed =="
[ $FAIL -eq 0 ]
