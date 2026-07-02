# fable-mode

Make Claude Opus 4.8 in Claude Code behave as much like Claude Fable 5 as
possible. The doctrine was transcribed by Fable 5 itself; hooks enforce it
at the harness level; an eval loop measures convergence against golden
Fable transcripts.

## What you get

- **Fable output style** — the doctrine in the system prompt (communication
  contract, turn discipline, autonomy calibration, honesty, code
  discipline, delegation).
- **Hooks** — doctrine card at session start and after compaction; per-prompt
  micro-nudges; a Stop gate that blocks "I'll do X next" turn endings; a
  PreToolUse gate against shell file-reads; a PostToolUse honesty nudge on
  failing output; PreCompact summary guidance. All deterministic, fail-open,
  <100ms. Local telemetry only (`~/.claude/fable-mode/telemetry.jsonl`).
- **Skills** — fable-voice, fable-fanout, fable-turn-check.
- **critic agent** — adversarial verification before big "done" claims.
- **Evals** — 12 probes, golden Fable transcripts, pairwise judge, report.

## Install

Marketplace (once listed): `/plugin marketplace add rennf93/opus-fable-playbook`
then `/plugin install fable-mode`. Direct: `claude --plugin-dir /path/to/opus-fable-playbook`.

## Activate

Merge `profiles/opus-fable.settings.json` into your settings (model,
effortLevel xhigh, alwaysThinkingEnabled, outputStyle "Fable"), or run
`/output-style fable` per session. Check posture anytime with
`/fable-status`. No plugin? Copy `docs/claude-md-snippet.md` into CLAUDE.md.
SDK/headless: `--append-system-prompt "$(cat output-styles/fable.md)"`.

## Strict mode & knobs

- `FABLE_STOP_JUDGE=1` — LLM second-tier stop gate (Haiku; ~2–5s per stop).
- `FABLE_TELEMETRY=0` — disable telemetry. `FABLE_TELEMETRY_FILE` — move it.

## The convergence loop

See `evals/LOOP.md`; run it via `/fable-eval`. Every accepted tuning
iteration bumps the version with a CHANGELOG entry.

## Composition with superpowers

fable-mode defers to superpowers for brainstorming, TDD, debugging, and
verification; it owns voice, orchestration shape, and turn-end discipline.
Precedence: user instructions > CLAUDE.md > skills > this doctrine.

## Platform

macOS/Linux (bash + python3 stdlib). Windows untested (WSL should work).

## What this can't do

Opus's reasoning depth is weights, not config. This playbook transplants
Fable's *behavior*, catches Opus's drift mechanically, and measures the
gap — it does not close the capability gap.
