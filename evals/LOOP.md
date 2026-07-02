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
