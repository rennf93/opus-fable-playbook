# Changelog

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
