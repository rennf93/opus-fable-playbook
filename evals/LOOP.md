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

**Means-based measurement gate (since phase B, 2026-07-03).** Step-5 keep-or-revert decisions require per-condition scores computed as means of ≥2 runs per probe (≥3 where affordable), and a per-dimension delta only counts as signal if it exceeds that dimension's measured run-to-run spread (current spreads: `docs/2026-07-04-phase-b-report.md`; method: `docs/2026-07-03-variance-study.md`). Single-run deltas are never acceptance evidence.

**Instructions-only arm (`claudemd` mode).** `evals/run-probe.sh PROBE claudemd OUTDIR` answers "isn't this plugin just a CLAUDE.md with extra fluff?" — it runs exactly like `baseline` (same isolation map, same `FABLE_CANDIDATE_MODEL`, no `--plugin-dir`, no profile merge) except it copies doctrine text into the run's workdir as `CLAUDE.md` before invoking `claude -p`, so the headless session auto-loads it as project memory. The default source is `hooks/lib/doctrine-card.md` — byte-identical to the fenced block `docs/claude-md-snippet.md` tells plugin-less users to paste — making this the honest instructions-only baseline: doctrine text alone, no hooks, no skills, no output style. Override the source file with `FABLE_CLAUDEMD_FILE` to eval any third-party CLAUDE.md against the same probe corpus, no code changes needed (documented in `docs/guide.md` §11). See `docs/2026-07-04-claudemd-arm-report.md` for the resulting three-way baseline-vs-claudemd-vs-fable study.

Golden regeneration must use `FABLE_GOLDEN_MODEL="claude-fable-5[1m]"` and afterwards assert every golden's dominant `modelUsage` cost bucket is `claude-fable-5` (probe 11's prompt is known to reroute to Opus on the standard pool). The `fable-turn-check` skill deliberately lists bare "Want me to…?" as a smell even though the mechanical stop-gate only blocks continuation-verb forms — the skill being stricter than the hook is intentional.

## Iteration log

- **2026-07-03, iteration 3 phase A** (measurement variance, no doctrine changes): 3 same-config fable runs → per-dimension spreads 0.00–0.33 (turn_completion 0.167, honesty 0.333, four dims at 0.083), 14/96 probe×dimension flips, closer_to_golden moved 2/12 between runs; 1 malformed-judge-output retry in 24 judge calls. Verdict (b): single-run 12-probe deltas of 0.083–0.17 are inside noise — see `docs/2026-07-03-variance-study.md`. Next: phase B must score conditions as multi-run means (≥3) and/or grow the probe set before any doctrine tuning.
- **2026-07-03/04, iteration 3 phase B** (corpus 12→24 + means-based baseline, no doctrine changes, v0.1.3): 12 new probes + 6 fixtures + goldens (the model assertion caught one `[1m]`-pool reroute on probe 15's golden, regenerated clean); 60 fresh runs scored as 2–3-run means with published spreads — real gaps: fable ahead on outcome_first/turn_completion/code_comment_discipline, behind on no_burial/delegation_parallelism; autonomy_calibration/honesty/tool_discipline within noise. Full tables: `docs/2026-07-04-phase-b-report.md`. Next tuning targets under the means gate: no_burial (−0.09) and the one stubborn delegation_parallelism probe (−0.04 with zero spread).
- **2026-07-04, iteration 3 phase C** (instructions-only `claudemd` arm, no doctrine changes): added a third measurement arm — baseline isolation, no plugin, doctrine text dropped in as `CLAUDE.md` — to test the "just a CLAUDE.md" claim directly. 48 fresh runs (2×24), reusing phase-B's baseline/fable data unchanged. Only one dimension shows a real hooks-attributable gap: `turn_completion` (fable−claudemd +0.06, zero spread both arms — traced to four new-12 probes where claudemd ends turns on a deferral/offer instead of finishing, exactly the pattern `stop-gate.sh` blocks). The doctrine text alone shows two real *regressions* against plain baseline: `no_burial` (−0.08) and `delegation_parallelism` (−0.04) — the hooks neither cause nor fix these, so they're a doctrine-content problem, not a harness one. Holistic counterpoint: claudemd's closer-to-golden tie rate (29%) sits close to fable's (30%), both well ahead of baseline's (19%) — most of the holistic "feels like Fable" gain comes from the text itself. Full protocol, tables, and plain-prose verdict: `docs/2026-07-04-claudemd-arm-report.md`.
