# The convergence loop

1. **Run**: `for p in evals/probes/*.md; do evals/run-probe.sh "$p" baseline evals/results/run1; evals/run-probe.sh "$p" fable evals/results/run1; done`
   (goldens already in `evals/golden/`; regenerate only when probes change).
2. **Judge**: `for p in evals/probes/*.md; do id=$(basename "$p" .md); for m in baseline fable; do evals/judge.sh "$p" "evals/results/run1/$id.$m.json" "evals/golden/$id.golden.json" evals/results/run1; done; done`
3. **Report**: `evals/report.sh evals/results/run1` — read the per-dimension
   table plus real-session telemetry counts.
4. **Distill**: for each weak dimension, strengthen EXACTLY ONE thing —
   the matching doctrine section (output style), a hook pattern, or a skill
   example. Map: outcome_first/no_burial → doctrine §1 + fable-voice;
   turn_completion → §2 + stop-gate patterns; autonomy_calibration → §3 +
   prompt-nudge heuristic; honesty → §4 + honesty-nudge signatures;
   delegation_parallelism → §6 + fable-fanout; tool_discipline → §6 +
   bash-discipline; code_comment_discipline → §5.
5. **Re-run** the affected probes, compare, keep or revert.
6. **Version**: every accepted iteration bumps the plugin version
   (plugin.json) with a CHANGELOG.md entry describing what was strengthened
   and the score delta.

Golden regeneration must use `FABLE_GOLDEN_MODEL="claude-fable-5[1m]"` and afterwards assert every golden's dominant `modelUsage` cost bucket is `claude-fable-5` (probe 11's prompt is known to reroute to Opus on the standard pool). The `fable-turn-check` skill deliberately lists bare "Want me to…?" as a smell even though the mechanical stop-gate only blocks continuation-verb forms — the skill being stricter than the hook is intentional.

## Iteration log

- **2026-07-03, iteration 3 phase A** (measurement variance, no doctrine changes): 3 same-config fable runs → per-dimension spreads 0.00–0.33 (turn_completion 0.167, honesty 0.333, four dims at 0.083), 14/96 probe×dimension flips, closer_to_golden moved 2/12 between runs; 1 malformed-judge-output retry in 24 judge calls. Verdict (b): single-run 12-probe deltas of 0.083–0.17 are inside noise — see `docs/2026-07-03-variance-study.md`. Next: phase B must score conditions as multi-run means (≥3) and/or grow the probe set before any doctrine tuning.
