# LOOP iteration 3 phase C: the instructions-only arm (`claudemd`)

**No doctrine changes in this phase.** This phase answers a specific public
claim head-on: that fable-mode is "just a CLAUDE.md with extra fluff" —
that pasting the doctrine text into project memory gets the same behavior
as installing the plugin, and the hooks/skills/output-style layers are
decoration. It adds a third arm to the existing baseline/fable measurement
and reuses the phase-B means protocol unchanged.

## Protocol

**What the `claudemd` arm is.** `evals/run-probe.sh PROBE claudemd OUTDIR`
runs identically to `baseline` — same generated isolation `--settings` map
(`evals/lib/isolation.py`), same `${FABLE_CANDIDATE_MODEL:-claude-opus-4-8}`,
no `--plugin-dir`, no profile merge — with exactly one addition: after the
fixture copy into the run's scratch workdir, the doctrine text is written
into that workdir as `CLAUDE.md`:

    cp "${FABLE_CLAUDEMD_FILE:-$ROOT/hooks/lib/doctrine-card.md}" "$WORK/CLAUDE.md"

Because `claude -p` runs with that workdir as its cwd, the headless session
auto-loads the file as ordinary project memory — no plugin, no hooks, no
skills, no output style, nothing but the text. The default source,
`hooks/lib/doctrine-card.md`, is byte-identical to the fenced block
`docs/claude-md-snippet.md` already tells plugin-less users to paste by
hand, so this is the honest instructions-only baseline, not a strawman.
`FABLE_CLAUDEMD_FILE` overrides which file gets copied, so any third-party
CLAUDE.md doctrine text can be evaled against the same 24-probe corpus with
zero code changes (documented in `docs/guide.md` §11 and `evals/LOOP.md`).

**Runs.** 2 fresh full runs of all 24 probes (`evals/results/claudemd-run1`,
`claudemd-run2`), sequential, retry-once, judged pairwise against the
committed goldens with the default judge (`claude-fable-5`, `evals/judge.sh`).
`baseline` and `fable` are **not** re-run: this phase reuses the exact
phase-B verdict data and mean/spread conventions
(`.superpowers/phaseb_analysis.py`, `docs/2026-07-04-phase-b-report.md`):

| arm | runs | source |
|---|---|---|
| baseline | 2 | reused: `2026-07-02` + `phaseb-old12-baseline-run2` (old-12), `phaseb-new12-baseline-run1/2` (new-12) |
| fable | 3 (old-12) / 2 (new-12) | reused: `2026-07-03` + `variance-run2` + `variance-run3` (old-12), `phaseb-new12-fable-run1/2` (new-12) |
| claudemd | 2 | fresh: `claudemd-run1`, `claudemd-run2` (flat 24-probe corpus, no old/new split needed) |

Per-dimension arm score = mean of the 24 per-probe means (each probe's mean
taken over that arm's runs of it). Spread = max−min of run-level dimension
averages: for baseline/fable, over the 2 paired full-corpus runs (pair *i* =
old-12 run *i* ∪ new-12 run *i*, unchanged from phase B); for claudemd, over
its 2 runs directly (one flat corpus, no pairing needed). One probe-flip on
a 24-probe corpus still moves a dimension average by 1/24 ≈ 0.042, the same
quantum as phase B — a gap only counts as real if it exceeds both the
measured spread and this quantum.

## Results

### Three-way, all 24 probes

| dimension | baseline | claudemd | fable | fable−claudemd | claudemd−baseline |
|---|---|---|---|---|---|
| outcome_first | 1.88 ± 0.000 | 1.90 ± 0.042 | 1.97 ± 0.083 | +0.07 | +0.02 |
| no_burial | 1.85 ± 0.042 | 1.77 ± 0.042 | 1.76 ± 0.042 | −0.01 | **−0.08** |
| turn_completion | 1.81 ± 0.042 | 1.83 ± 0.000 | 1.90 ± 0.000 | **+0.06** | +0.02 |
| autonomy_calibration | 1.81 ± 0.042 | 1.81 ± 0.042 | 1.81 ± 0.042 | −0.01 | 0.00 |
| honesty | 1.83 ± 0.083 | 1.85 ± 0.042 | 1.83 ± 0.083 | −0.03 | +0.02 |
| delegation_parallelism | 2.00 ± 0.000 | 1.96 ± 0.000 | 1.96 ± 0.000 | 0.00 | **−0.04** |
| tool_discipline | 1.92 ± 0.000 | 1.92 ± 0.083 | 1.91 ± 0.000 | −0.01 | 0.00 |
| code_comment_discipline | 1.96 ± 0.000 | 1.98 ± 0.042 | 2.00 ± 0.000 | +0.02 | +0.02 |

Bold marks gaps that are real under the LOOP.md gate (exceed both the
measured spread and the one-flip quantum of 0.042).

### closer_to_golden (pooled over every probe-run verdict)

- baseline: `{'golden': 39, 'tie': 9}` over 48 verdicts — tie rate 19%
- claudemd: `{'golden': 34, 'tie': 14}` over 48 verdicts — tie rate 29%
- fable: `{'golden': 42, 'tie': 18}` over 60 verdicts — tie rate 30%

No arm ever beat its golden outright.

## Which gaps are real

- **Real, fable ahead of claudemd:** `turn_completion` only (+0.06, zero
  measured spread on *both* arms across their runs — the cleanest signal in
  this study). Traced to specific probes below.
- **Real, claudemd behind baseline:** `no_burial` (−0.08) and
  `delegation_parallelism` (−0.04, exactly one flip). Both are regressions
  — pasting the doctrine text in measurably *hurts* these two dimensions
  relative to running the same model with no doctrine at all.
- **Noise (sub-spread or sub-flip) everywhere else:** `outcome_first`
  (fable−claudemd +0.07 sits just under its own 0.083 spread — suggestive,
  not conclusive), `autonomy_calibration`, `honesty`, `tool_discipline`,
  `code_comment_discipline` — no leg of this three-way split clears the bar
  on any of these, even though fable's own code_comment_discipline edge
  over baseline was real in phase B (+0.04); that edge doesn't decompose
  cleanly onto either the text or the hooks individually at this sample size.

**What actually happens on the turn_completion gap.** Four new-12 probes —
`14-midway-error`, `17-warning-success`, `18-false-assertion`,
`21-root-cause-first` — each show claudemd scoring 1 on at least one of its
two runs while fable scores a clean 2/2 on all four. The judge's stated
reasons are the same shape every time: the candidate does the work correctly
and states the outcome, then closes with an offer or a deferral instead of
finishing — *"If you want, I can install pytest,"* *"install pytest if you
want the normal workflow,"* a hand-rolled test driver with a dangling
*"say the word"* instead of just running `uvx pytest` the way the golden
did. That is exactly the pattern `stop-gate.sh` is built to catch
mechanically and force a retry on; it fires only when the plugin's hooks
are loaded, which they are not in claudemd mode.

## Verdict

**What do the hooks add over the doctrine text alone (fable − claudemd)?**
One dimension clears the bar: `turn_completion`, and the mechanism is
visible in the rationale text, not just the number — see above. Every
other dimension's fable-vs-claudemd gap is noise under the gate. So on
this 8-dimension rubric, the hooks/skills/output-style layer's
demonstrable, repeatable contribution is turn-completion enforcement, not
a broad uplift across the board.

**What does the text alone add over nothing (claudemd − baseline)?** Two
dimensions clear the bar, and both are regressions: `no_burial` and
`delegation_parallelism`. This is not a hooks problem — fable-mode's own
candidates show nearly identical regressions against baseline in the
phase-B measurement (−0.09 and −0.04), and the fable-vs-claudemd gap on
both dimensions is itself noise (−0.01, 0.00), meaning the hooks neither
cause nor fix it. It reads as a property of the doctrine text's content —
plausibly its own emphasis on outcome-first brevity and decisive action
working against burial-avoidance and delegation instincts. No dimension
shows a clean, real, positive claudemd-over-baseline gain; `outcome_first`
comes closest (+0.02) but sits well inside its own spread.

**The holistic counterpoint.** Per dimension, the story above reads as
"hooks barely move the needle, and the text can actively hurt." The
pairwise closer-to-golden verdict tells a more generous story: baseline
ties its golden 19% of the time, claudemd 29%, fable 30%. By the judge's
holistic read of which transcript feels more like Fable, the doctrine text
alone recovers nearly all of the gap between baseline and the full plugin
— claudemd's tie rate sits a hair under fable's, both well ahead of
baseline's.

**Answering the actual claim.** "Just a CLAUDE.md with extra fluff" is
closer to true than false on these numbers, with one real exception. Most
of what makes fable-mode candidates read as Fable-like, by the holistic
judge, comes from the doctrine text itself — the hooks' only demonstrable,
repeatable per-dimension contribution measured here is mechanically
forcing turns to finish instead of deferring, a genuine difference with
zero measured noise behind it. The text alone is not something an adopter
can skip for free, either: it moves the holistic tie rate from 19% to 29%
on its own, and it introduces two real regressions (`no_burial`,
`delegation_parallelism`) that the hooks do not fix — a plugin-less
adopter following `docs/claude-md-snippet.md` literally gets worse burial
and delegation behavior than doing nothing at all, a tradeoff the current
README/guide framing does not surface.

## Retries, failures, cost

- Probe runs: 48 fresh, 1 retry-once recovery
  (`16-premise-contradiction`/claudemd-run2, clean on attempt 2), 0 hard
  failures.
- Judge calls: 4 malformed-output retries across 48 calls (8.3%, in line
  with prior iterations' ~13% observed rate), all clean on retry, 0 hard
  failures.
- Cost: $10.08 across the 48 candidate transcripts by `total_cost_usd`;
  judge-call cost is not captured by the harness (consistent with prior
  reports).

## Artifacts

- Analysis: `.superpowers/claudemd_analysis.py` →
  `.superpowers/claudemd_summary.json` (gitignored, machine-readable copy
  of every table above).
- Raw runs/verdicts: `evals/results/claudemd-run1/`,
  `evals/results/claudemd-run2/` (gitignored, local).
- Mode implementation: `evals/run-probe.sh` (`claudemd` case arm),
  `FABLE_CLAUDEMD_FILE` env var (`docs/guide.md` §11, `evals/LOOP.md`).
