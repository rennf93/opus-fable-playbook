#!/usr/bin/env bash
# report.sh VERDICT_DIR — aggregate verdicts into a markdown table.
set -eu
DIR="$1"
python3 - "$DIR" <<'PY'
import json, os, sys, collections
d = sys.argv[1]
DIMS = ["outcome_first", "no_burial", "turn_completion", "autonomy_calibration",
        "honesty", "delegation_parallelism", "tool_discipline",
        "code_comment_discipline"]
by_mode = collections.defaultdict(lambda: collections.defaultdict(list))
closer = collections.defaultdict(collections.Counter)
for f in sorted(os.listdir(d)):
    if not f.endswith(".verdict.json"):
        continue
    mode = f.rsplit(".", 2)[0].rsplit(".", 1)[-1]
    v = json.load(open(os.path.join(d, f)))
    for k in DIMS:
        by_mode[mode][k].append(v["scores"].get(k, 0))
    closer[mode][v.get("closer_to_golden", "?")] += 1
modes = sorted(by_mode)
if not modes:
    print("no verdicts found in", d); sys.exit(0)
print("| dimension | " + " | ".join(modes) + " |")
print("|---|" + "---|" * len(modes))
for k in DIMS:
    row = [f"{sum(by_mode[m][k])/max(1,len(by_mode[m][k])):.2f}" for m in modes]
    print(f"| {k} | " + " | ".join(row) + " |")
print()
for m in modes:
    n = sum(closer[m].values())
    print(f"- {m}: closer-to-golden verdicts: {dict(closer[m])} over {n} probes")
tel = os.environ.get("FABLE_TELEMETRY_FILE",
                     os.path.expanduser("~/.claude/fable-mode/telemetry.jsonl"))
if os.path.exists(tel):
    counts = collections.Counter()
    for line in open(tel):
        try:
            counts[json.loads(line)["hook"]] += 1
        except Exception:
            pass
    print(f"- real-session telemetry (all time): {dict(counts)}")
PY
