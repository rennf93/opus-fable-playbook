---
description: Report fable-mode posture — output style, model/effort, hook telemetry drift counts
---

Report the current fable-mode posture. Steps:

1. Read `~/.claude/settings.json` (and `.claude/settings.local.json` if
   present). Report: `outputStyle` (is it `Fable`?), `model`, `effortLevel`,
   `alwaysThinkingEnabled`.
2. Summarize hook drift telemetry by running:

```bash
python3 - <<'PY'
import calendar, json, os, time
path = os.environ.get("FABLE_TELEMETRY_FILE",
                      os.path.expanduser("~/.claude/fable-mode/telemetry.jsonl"))
cutoff = time.time() - 7 * 86400
counts = {}
try:
    for line in open(path):
        try:
            e = json.loads(line)
            ts = calendar.timegm(time.strptime(e["ts"], "%Y-%m-%dT%H:%M:%SZ"))
            if ts >= cutoff:
                key = (e["hook"], e["pattern"])
                counts[key] = counts.get(key, 0) + 1
        except Exception:
            continue
except FileNotFoundError:
    pass
if not counts:
    print("no telemetry events in the last 7 days")
for (hook, pattern), n in sorted(counts.items(), key=lambda kv: -kv[1]):
    print(f"{n:4d}  {hook}  {pattern}")
PY
```

3. Interpret: `stop-gate` counts mean turn-discipline drift (doctrine §2);
   `stop-gate-subagent` counts mean subagent turn-discipline drift
   (subagents returning intentions instead of findings); `bash-discipline`
   means tool-discipline drift (§6); `honesty-nudge` firings are
   informational (failures occurred and were flagged).
4. Report in prose, outcome first: overall posture, then the table framed
   as the week's enforcement tax — each count is drift the plugin caught
   that would otherwise have shipped — then which doctrine section (if
   any) needs reinforcement per LOOP.md, then one line on how to disable
   (`/plugin` → disable fable-mode; unset `outputStyle`).
