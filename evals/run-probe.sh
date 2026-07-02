#!/usr/bin/env bash
# run-probe.sh PROBE_FILE MODE OUTDIR   (MODE: baseline|fable|golden)
set -eu
PROBE="$1"; MODE="$2"; OUTDIR="$3"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$OUTDIR"

meta() { python3 - "$PROBE" "$1" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
fm = dict(l.split(":", 1) for l in m.group(1).splitlines() if ":" in l)
fm = {k.strip(): v.strip() for k, v in fm.items()}
body = m.group(2).split("## Expected Fable behavior")[0].strip()
print(fm.get(sys.argv[2], "") if sys.argv[2] != "_prompt" else body)
PY
}

ID="$(meta id)"; MAXT="$(meta max_turns)"; FIXTURE="$(meta fixture)"
PROMPT="$(meta _prompt)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
if [ -n "$FIXTURE" ]; then cp -R "$ROOT/evals/fixtures/$FIXTURE/." "$WORK/"; fi

# Isolation: a generated plugin-disable settings map instead of --bare
# (--bare would also drop OAuth/subscription auth — spec amendment 2026-07-02).
case "$MODE" in
  baseline) MODEL="${FABLE_CANDIDATE_MODEL:-claude-opus-4-8}"
            python3 "$ROOT/evals/lib/isolation.py" > "$WORK/.iso.settings.json"
            grep -q '"enabledPlugins"' "$WORK/.iso.settings.json" || { echo "fable-eval: isolation map generation failed; refusing to run unisolated" >&2; exit 1; }
            EXTRA="--settings $WORK/.iso.settings.json" ;;
  fable)    MODEL="${FABLE_CANDIDATE_MODEL:-claude-opus-4-8}"
            python3 "$ROOT/evals/lib/isolation.py" --merge "$ROOT/profiles/opus-fable.settings.json" > "$WORK/.iso.settings.json"
            grep -q '"enabledPlugins"' "$WORK/.iso.settings.json" || { echo "fable-eval: isolation map generation failed; refusing to run unisolated" >&2; exit 1; }
            EXTRA="--plugin-dir $ROOT --settings $WORK/.iso.settings.json" ;;
  golden)   MODEL="${FABLE_GOLDEN_MODEL:-claude-fable-5}"
            python3 "$ROOT/evals/lib/isolation.py" > "$WORK/.iso.settings.json"
            grep -q '"enabledPlugins"' "$WORK/.iso.settings.json" || { echo "fable-eval: isolation map generation failed; refusing to run unisolated" >&2; exit 1; }
            EXTRA="--settings $WORK/.iso.settings.json" ;;
  *) echo "unknown mode: $MODE" >&2; exit 1 ;;
esac

OUT="$OUTDIR/$ID.$MODE.json"
# shellcheck disable=SC2086
set -- claude -p "$PROMPT" --model "$MODEL" $EXTRA \
  --output-format json --max-turns "$MAXT" \
  --permission-mode acceptEdits \
  --allowedTools "Bash,Read,Edit,Write,Grep,Glob,Agent"

if [ "${FABLE_EVAL_DRY_RUN:-0}" = "1" ]; then printf '%s ' "$@"; echo; exit 0; fi
( cd "$WORK" && "$@" ) > "$OUT"
echo "wrote $OUT"
