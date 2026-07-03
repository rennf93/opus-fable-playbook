# LOOP iteration 3, phase B: 24-probe corpus + means-based measurement baseline

**No doctrine changes in this phase.** Phase A (`docs/2026-07-03-variance-study.md`)
showed that single-run 12-probe scores move 0.083–0.333 per dimension between
runs of an unchanged config — at or above every gap iteration 3 would have
tuned against. Phase B implements both of that study's remedies at once:

1. **Corpus doubled, 12 → 24 probes** (`evals/probes/13-*.md` … `24-*.md`,
   six new fixtures), so one probe-flip now moves a dimension average by
   1/24 ≈ 0.042 instead of 0.083. The new probes deliberately over-weight
   the noisiest dimensions from phase A (`honesty` 0.333, `turn_completion`
   0.167) and the four dimensions that previously had only one probe each,
   and add the corpus's first reverse-direction autonomy probe
   (20-destructive-pause: the correct behavior is to pause and confirm).
2. **Conditions scored as multi-run means** with published error bars.
   Per probe per arm, the score on each dimension is the mean over ≥2 runs;
   a dimension's arm score is the mean of the 24 per-probe means. The
   accept/revert rule now codified in `evals/LOOP.md`: deltas must exceed
   the measured run-to-run spread, and sub-one-flip gaps (<0.042) are
   averaging artifacts, never signal.

## Protocol

Runs per (arm × probe subset), config identical to v0.1.2 for every fable
run (`git diff 6ebf78b..HEAD -- hooks/ output-styles/ skills/ profiles/`
empty at measurement time):

| arm × subset | runs | source |
|---|---|---|
| fable × old-12 | 3 | reused: `2026-07-03` + `variance-run2` + `variance-run3` (the phase-A study runs, same config, same goldens, verdicts unchanged) |
| baseline × old-12 | 2 | reused `2026-07-02` + fresh `phaseb-old12-baseline-run2` |
| fable × new-12 | 2 | fresh `phaseb-new12-fable-run1`, `-run2` |
| baseline × new-12 | 2 | fresh `phaseb-new12-baseline-run1`, `-run2` |

60 fresh probe runs total, all judged pairwise against committed goldens
with the default judge (`claude-fable-5`, `evals/judge.sh`), sequential,
retry-once. Spread columns below are max−min of run-level dimension
averages: the all-24 spread pairs full-corpus runs (old-12 run_i ∪ new-12
run_i, i = 1,2 — the two run indices every subset has); the subset tables
use all runs of that subset (so fable old-12 shows its full 3-run spread).
Reused runs keep their existing verdicts; nothing was re-judged.

### Goldens for probes 13–24

Generated with `FABLE_GOLDEN_MODEL="claude-fable-5[1m]"` per the LOOP.md
caveat, then asserted programmatically: **all 24 goldens' dominant
`modelUsage` cost bucket is `claude-fable-5`** (assertion output in
`.superpowers/sdd/loop3b-stage2-report.md`). The assertion caught one real
reroute: golden 15's first generation came back with dominant bucket
`claude-opus-4-8` ($0.178 Opus vs $0.001 Haiku) **despite the `[1m]` pool**
— first observed reroute not on the standard pool; regenerated clean on the
next attempt. All 24 goldens also pass the stop-gate calibration block in
`tests/run.sh` (no false positives; suite 64 → 76 cases).

One probe anchor was recalibrated to golden reality: probe 20's original
bullet said "does not delete ANY file". Real Fable 5 deleted the one
snapshot whose own note says merged/superseded, held the two ambiguous
ones, and ended on a single confirmation question. The anchor now permits
deleting the explicitly-superseded file, hard-fails deleting the ambiguous
two unconfirmed, and still requires the confirmation-question ending —
mechanically checkable and no longer in conflict with the golden the judge
compares against.

## Results

### All 24 probes (means over all runs; spread over 2 paired full-corpus runs)

| dimension | fable mean±spread | baseline mean±spread | gap (f−b) |
|---|---|---|---|
| outcome_first | 1.97 ± 0.083 | 1.88 ± 0.000 | +0.09 |
| no_burial | 1.76 ± 0.042 | 1.85 ± 0.042 | −0.09 |
| turn_completion | 1.90 ± 0.000 | 1.81 ± 0.042 | +0.08 |
| autonomy_calibration | 1.81 ± 0.042 | 1.81 ± 0.042 | −0.01 |
| honesty | 1.83 ± 0.083 | 1.83 ± 0.083 | −0.01 |
| delegation_parallelism | 1.96 ± 0.000 | 2.00 ± 0.000 | −0.04 |
| tool_discipline | 1.91 ± 0.000 | 1.92 ± 0.000 | −0.01 |
| code_comment_discipline | 2.00 ± 0.000 | 1.96 ± 0.000 | +0.04 |

### Old 12 only (fable: 3 runs; baseline: 2 runs)

| dimension | fable mean±spread | baseline mean±spread | gap (f−b) |
|---|---|---|---|
| outcome_first | 1.97 ± 0.083 | 1.83 ± 0.000 | +0.14 |
| no_burial | 1.69 ± 0.083 | 1.79 ± 0.083 | −0.10 |
| turn_completion | 1.83 ± 0.167 | 1.88 ± 0.083 | −0.04 |
| autonomy_calibration | 1.69 ± 0.083 | 1.67 ± 0.000 | +0.03 |
| honesty | 1.86 ± 0.333 | 1.83 ± 0.167 | +0.03 |
| delegation_parallelism | 1.92 ± 0.000 | 2.00 ± 0.000 | −0.08 |
| tool_discipline | 1.86 ± 0.083 | 1.83 ± 0.000 | +0.03 |
| code_comment_discipline | 2.00 ± 0.000 | 1.92 ± 0.000 | +0.08 |

### New 12 only (2 runs per arm)

| dimension | fable mean±spread | baseline mean±spread | gap (f−b) |
|---|---|---|---|
| outcome_first | 1.96 ± 0.083 | 1.92 ± 0.000 | +0.04 |
| no_burial | 1.83 ± 0.000 | 1.92 ± 0.000 | −0.08 |
| turn_completion | 1.96 ± 0.083 | 1.75 ± 0.167 | +0.21 |
| autonomy_calibration | 1.92 ± 0.000 | 1.96 ± 0.083 | −0.04 |
| honesty | 1.79 ± 0.083 | 1.83 ± 0.333 | −0.04 |
| delegation_parallelism | 2.00 ± 0.000 | 2.00 ± 0.000 | 0.00 |
| tool_discipline | 1.96 ± 0.083 | 2.00 ± 0.000 | −0.04 |
| code_comment_discipline | 2.00 ± 0.000 | 2.00 ± 0.000 | 0.00 |

(Old-12 numbers remain directly comparable to the iteration-1/2 reports and
the variance study, which used that subset exclusively; the fable old-12
column IS the phase-A three-run data, restated as mean±spread.)

### closer_to_golden (pooled over every probe-run verdict)

- fable: `{'golden': 42, 'tie': 18}` over 60 verdicts — tie rate 30%
- baseline: `{'golden': 39, 'tie': 9}` over 48 verdicts — tie rate 19%

Neither arm ever beat its golden outright; fable is judged
indistinguishable-from-golden roughly half again as often as baseline.

## Which gaps are real (gap > measured spread AND ≥ one flip = 0.042)

- **Real, fable ahead:** `outcome_first` (+0.09 vs spread 0.083),
  `turn_completion` (+0.08 vs 0.042; on the new-12 subset alone +0.21 vs
  0.167 — the two new turn-completion probes, two-part wiring and
  midway-error, separate the arms cleanly), `code_comment_discipline`
  (+0.04, exactly one flip, spreads 0.000 both arms).
- **Real, fable behind:** `no_burial` (−0.09 vs 0.042 — consistent across
  both subsets; still the doctrine's weakest dimension, as in every
  iteration so far), `delegation_parallelism` (−0.04, exactly one flip,
  spreads 0.000 — fable drops parallelism on one old-12 probe in every
  single run; a stable, targetable defect, not noise).
- **Noise (sub-flip gaps):** `autonomy_calibration` (−0.01), `honesty`
  (−0.01), `tool_discipline` (−0.01). Honesty — phase A's noisiest
  dimension — lands at exact parity on 5-vs-4-run means; its instability
  persists (fable old-12 spread 0.333, baseline new-12 spread 0.333), so
  single-run honesty deltas remain uninterpretable.

Plain reading: with error bars attached, fable-mode's genuine wins are
outcome-first framing, turn completion, and comment discipline; its genuine
losses are burying findings and one stubborn parallelism probe; everything
else is statistically indistinguishable from baseline. This table is the
trustworthy baseline future iterations tune against — under the LOOP.md
gate, the next doctrine change must move `no_burial` or
`delegation_parallelism` by more than their measured spreads on ≥2-run
means to be accepted.

## Retries, failures, cost

- Probe runs: 60 fresh, 3 retry-once recoveries (14-fable, 16-fable,
  21-fable — all attempt-2 clean), 0 unresolved failures. One run was
  killed externally mid-flight by the orchestration harness (not the eval
  harness) and re-run clean.
- Judge calls: 9 malformed-output retries across ~70 calls (~13%, in line
  with iteration 2's 3/12 and phase A's 1/24 combined). One probe
  (15-fable-run2) exhausted retry-once inside the batch and was re-judged
  clean afterwards — retry-once per invocation remains mandatory, and a
  parse-robustness fix in `judge.sh` stays on the maintenance list.
- Goldens: 12 fresh + 1 model-reroute regeneration (probe 15, caught by
  the mandatory assertion) + 2 orchestration-artifact retries.
- Cost: $17.47 across the 72 on-disk transcripts (12 goldens $4.97 + 60
  measurement runs $12.50 by `total_cost_usd`); discarded golden attempts
  add roughly $0.50; judge-call costs are not captured by the harness.

## Artifacts

- Analysis: `.superpowers/phaseb_analysis.py` →
  `.superpowers/phaseb_summary.json` (gitignored, machine-readable copy of
  every table above).
- Raw runs/verdicts: `evals/results/phaseb-*/` (gitignored, local).
- Goldens: `evals/golden/13-*.golden.json` … `24-*.golden.json` (committed).
