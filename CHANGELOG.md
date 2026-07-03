# Changelog

## 0.1.3 — 2026-07-04

LOOP iteration 3 phase B: eval corpus doubled to 24 probes (12 new probes,
13–24, targeting the variance study's noisiest dimensions plus previously
single-probe dimensions; first reverse-direction autonomy probe where
pausing to confirm is the correct behavior) with 6 new fixtures and
committed goldens (generated on `claude-fable-5[1m]`; the mandatory model
assertion caught and fixed one pool reroute on probe 15). Measurement is
now means-based: conditions are scored as 2–3-run means with published
run-to-run spreads, and LOOP.md codifies the gate — accept/revert
decisions require ≥2-run means and deltas exceeding both the measured
spread and the one-probe-flip quantum (0.042). New trustworthy baseline
(docs/2026-07-04-phase-b-report.md): fable-mode genuinely ahead on
outcome_first (+0.09), turn_completion (+0.08), code_comment_discipline
(+0.04); genuinely behind on no_burial (−0.09) and delegation_parallelism
(−0.04); autonomy_calibration, honesty, and tool_discipline within noise.
No doctrine changes. Tests 64→76 (12 new golden stop-gate calibration
cases). README and guide §9 updated to the means±spread numbers.

## 0.1.2 — 2026-07-03

User guide (docs/guide.md), slimmed README, macOS CI job, internal dev
docs removed from the repo, /fable-status subagent interpretation.

LOOP iteration 2 (no_burial + autonomy_calibration, per the iteration-1
verdict rationales): doctrine §1 and fable-voice now state that a bare
"done/verified" never substitutes for the concrete facts behind it (the
"contentless closer" pattern that cost probes 04/07); prompt-nudge's
question-shape heuristic widened to catch imperative-phrased assessment
requests ("...where this project stands", the probe-03 miss), and
question-shaped prompts now get ONLY the assessment reminder instead of
also receiving finish-the-work pressure. Measured on 12 fresh fable
candidates against unchanged baseline/goldens
(docs/2026-07-03-iteration-2-report.md): no_burial 1.42→1.75,
autonomy_calibration 1.50→1.75 (now above baseline's 1.67), honesty
1.83→2.00, tool_discipline 1.75→1.92, code_comment_discipline 1.92→2.00,
outcome_first held 2.00, turn_completion 2.00→1.83 (at baseline, within
gate). Three guide fixes from dogfooding §10 on real smoke sessions
(enforcement tax across the three sessions: 1 honesty-nudge
failure-output, 0 stop-gate, 0 bash-discipline): the recipe's example
commands now carry --permission-mode/--allowedTools (plain -p aborts on
its first edit), the fixture actually contains the duplication its third
prompt describes, and the telemetry read-back list includes
stop-gate-subagent. Tests 61→64.

## 0.1.1 — 2026-07-02

Post-release corrections from the final whole-branch review: golden 11
regenerated as a true Fable 5 transcript (the standard pool served this
probe from Opus; regeneration pins `claude-fable-5[1m]`); isolation map
hardened (merge failures keep the disable map) and now validated by
callers before any eval runs; the opt-in stop-judge no longer uses
`--bare` (broken under OAuth-only auth); marketplace manifest added so
the README install path works; eval-pipeline guards (probe id/fixture
gating, five stop-gate positive fixtures) and LOOP regeneration notes.

## 0.1.0 — 2026-07-02

Initial release: Fable doctrine output style; session/prompt/stop/bash/
honesty/precompact hooks with local telemetry; fable-voice, fable-fanout,
fable-turn-check skills; critic agent; /fable-status and /fable-eval;
12-probe eval harness with golden Fable transcripts and pairwise judge;
baseline report committed under docs/.
