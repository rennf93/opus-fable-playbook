# Opus-Fable Playbook — Design Spec

**Date:** 2026-07-02
**Status:** Approved (approach C, fullest scope) — 2026-07-02. Repo connected to GitHub; push authorized.
**Goal:** Make Claude Opus 4.8 in Claude Code behave as much like Claude Fable 5 as possible, packaged as a self-contained, shareable Claude Code plugin (`fable-mode`) living in this repo.

---

## 1. Goal and non-goals

Fable 5's edge over Opus 4.8 has two parts:

1. **Doctrine** — the behavioral contract in Fable's system prompt (communication style, turn discipline, autonomy calibration, honesty, delegation). This is *text* and can be transplanted.
2. **Disposition** — deeper reasoning and trained-in judgment. This is *weights* and cannot be transplanted — but its most visible failure modes in Opus can be caught mechanically by the harness (hooks) and scaffolded by skills.

This project transplants the doctrine, enforces it mechanically, scaffolds Fable-style orchestration, and measures convergence with an eval loop against golden Fable transcripts.

**Non-goals:**
- Making Opus reason more deeply than its weights allow.
- Replicating Fable-only harness tools (Workflow, ScheduleWakeup). We approximate multi-agent orchestration with the standard Agent tool.
- Replacing or duplicating the superpowers plugin. The playbook composes with it and defers to it where it already covers a behavior (brainstorming, TDD, verification-before-completion).

**Source material:** the doctrine content is a first-person transcription of Fable 5's actual operating rules, written by Fable 5. This is the project's unique asset — not a guess at what Fable does, but the thing itself.

## 2. The spine: Opus failure modes → levers

Each Opus 4.8 drift (relative to Fable) maps to a primary lever plus a backstop:

| # | Opus drift vs Fable | Primary lever | Backstop |
|---|---------------------|---------------|----------|
| 1 | Ends turns narrating next steps ("I'll…", "Shall I…?") instead of doing them | Output style | Stop-gate hook |
| 2 | Buries the lede; header/bullet spam for simple questions; process-narration summaries | Output style | `fable-voice` skill |
| 3 | Asks permission for reversible, in-scope steps | Output style | UserPromptSubmit nudge |
| 4 | Applies fixes when asked only to assess | Output style | UserPromptSubmit question-shape heuristic |
| 5 | Serial tool calls; stuffs whole files into context instead of delegating | `fable-fanout` skill | PreToolUse Bash gate |
| 6 | Re-reads files after editing them | Output style | — |
| 7 | Claims "should work now" without running anything | superpowers `verification-before-completion` (defer) | Stop-gate judge tier (opt-in) |
| 8 | Sycophancy openers, hedged conclusions after verification | Output style | Eval rubric dimension |
| 9 | Reviewer-directed code comments ("// now we handle X") | Output style | Eval probe |
| 10 | Long-session doctrine drift (forgets rules post-compaction) | SessionStart re-inject on `compact` | UserPromptSubmit micro-reminder |

## 3. Approaches considered

- **A. Doctrine pack only** (output style + CLAUDE.md card + skills). Zero runtime overhead, trivial install — but relies entirely on instruction-following, which is exactly what drifts over long sessions, and gives no way to measure whether it works.
- **B. Doctrine + harness enforcement** (A + deterministic hooks + agents). Attacks drift mechanically: the harness re-anchors doctrine every prompt and blocks the classic Opus failure (stopping early) at the exact moment it happens. More moving parts; Stop-gate needs careful anti-loop design.
- **C. B + eval-driven distillation** (B + probes, golden Fable transcripts, pairwise judge). The only version that *converges*: you find out which rules Opus actually ignores and reinforce just those. Most effort; eval runs cost tokens.

**Chosen: C, built in three phases** so each layer ships independently useful: P1 doctrine → P2 enforcement → P3 convergence.

## 4. Components

### C1. Output style — `output-styles/fable.md` (the core)

The highest-leverage channel: it lives in the system prompt itself, persists all session, and survives context pressure better than user-message instructions.

- Frontmatter: `name: Fable`, `description`, **`keep-coding-instructions: true`** (critical — without it the style *replaces* Claude Code's coding instructions), `force-for-plugin: false` (the user's main model is Fable 5 itself; auto-forcing the style onto every session with the plugin enabled would be redundant there — activation is explicit, per profile/project).
- Content (~700–900 words, imperative voice), transcribed from Fable's doctrine:
  1. **Communication contract** — lead with the outcome (first sentence answers "what happened"); write for a teammate catching up, not a log file; readable beats concise — selectivity over compression; complete sentences, no arrow-chains/fragment-speak; prose-first, headers only when structure genuinely helps, tables only for short enumerable facts; everything the user needs goes in the **final** message of the turn; one-sentence intent note before the first tool call; surface load-bearing findings when they happen.
  2. **Turn discipline** — before ending, check the last paragraph: if it is a plan, a question that isn't blocking, next steps, or a promise ("I'll…", "Let me know when…"), do that work now; retry after errors; gather missing information yourself; end only when done or blocked on input only the user can provide.
  3. **Autonomy calibration** — proceed without asking for reversible actions that follow from the request; stop for destructive actions or genuine scope changes; when the user is describing a problem or asking a question, the deliverable is assessment — report findings and stop; don't fix until asked.
  4. **Honesty** — report outcomes faithfully: failing tests reported with their output, skipped steps stated, verified results stated plainly without hedging; no sycophancy openers; check evidence before state-changing commands; look at a target before deleting/overwriting and surface contradictions.
  5. **Code discipline** — match surrounding idiom and comment density; comment only constraints the code cannot show; never comments that talk to the reviewer; don't re-read files just edited to verify.
  6. **Delegation & parallelism** — independent tool calls go in one parallel block; fan out subagents for independent units of work; delegate broad searches and keep conclusions, not file dumps; prefer dedicated file/search tools over shell equivalents; read only the needed part of large files.
  7. **Precedence** — user instructions and CLAUDE.md outrank this style; installed skills (e.g. superpowers) govern their domains; this doctrine governs where they are silent.

### C2. Hooks — `hooks/hooks.json` + `hooks/*.sh`

All hooks: bash + `python3` one-liners for JSON (no jq dependency), fail-open (script error → exit 0), tier-1 budget <100ms, no network.

1. **SessionStart** (`matcher: startup|clear|compact|resume`) → inject the **doctrine card** (~250-token compression of C1, same 7 headings) plus a pointer to the three playbook skills and their trigger rules. The `compact` matcher is the drift killer: doctrine gets re-anchored exactly when context surgery would otherwise erase it. If the active output style isn't `Fable`, the card says so and recommends `/output-style fable`.
2. **UserPromptSubmit** → deterministic micro-nudge (≤40 tokens) as `additionalContext`: base reminder "Outcome-first final message. Finish, don't narrate. Parallelize independent work." If the prompt is question-shaped (ends in `?`, or starts with why/what/how/is/does/should/can), append: "Question-shaped prompt: deliver assessment; don't change code unless asked."
3. **Stop** → `stop-gate.sh`, the flagship:
   - Guard: `stop_hook_active == true` → exit 0 (single-block semantics: at most one forced continuation per stop attempt — safe by construction; the documented 8-block cap is a second fence we never reach).
   - Tier 1 (always on, regex over the last assistant message, extracted from `transcript_path` by a small python helper): flag endings that *promise or propose* instead of *do* — a final paragraph containing trailing patterns like "I'll / I will / Next steps: / Let me know / Would you like / Shall I / Want me to". Question-endings that name a genuine user decision are **not** flagged. Semantic cases regex can't catch (e.g. an unexecuted plan written as prose) are the judge tier's job, not tier 1's.
   - On flag → `{"decision": "block", "reason": "Fable turn discipline: your last paragraph promises or proposes work instead of doing it. Do that work now. If you are genuinely blocked on the user, state the blocking question plainly and stop."}`
   - Tier 2 (opt-in via `FABLE_STOP_JUDGE=1`): pipe the last message to `claude -p --model claude-haiku-4-5 --bare` with a 10-line rubric → verdict JSON → block/allow. ~2–5s latency per stop; off by default.
4. **SubagentStop** → tier-1 only, reworded reason ("return findings, not intentions").
5. **PreToolUse** (`matcher: Bash`) → `bash-discipline.sh`: deny-with-reason for pure shell file-reads where a dedicated tool exists. Initial pattern set (conservative, exact): commands matching `^cat <path>`, `^head …`, `^tail …`, `^less/^more <path>`, `^sed -n '…p' <path>` with **no pipe** in the command. Anything piped into further processing passes. Reason text: "Use the Read/Grep tools instead of shell file-reads (Fable tool discipline)." Denials are feedback to the model, not user prompts.
6. **PostToolUse** (`matcher: Bash`) → `honesty-nudge.sh`: when the tool result contains test-failure signatures (conservative set: pytest `FAILED`/`ERRORS`, jest `Tests: .* failed`, `cargo test … FAILED`, go `--- FAIL`, generic `AssertionError`), inject `additionalContext`: "A command just failed or reported failing tests. Fable honesty rule: report this outcome verbatim in your final message — do not gloss it as 'mostly working'." Never blocks. *Exact PostToolUse additionalContext contract to be re-verified against docs at implementation time.*
7. **PreCompact** (`matcher: manual|auto`) → inject compaction guidance: the summary must preserve, outcome-first: current task state, what was verified (with results), unreported failures, and pending user decisions. Guards the drift point from the opposite side of SessionStart's `compact` re-injection. *Exact PreCompact injection contract to be re-verified at implementation time.*

**Telemetry:** every stop-gate block, subagent-stop block, bash-discipline denial, and honesty-nudge firing appends one JSON line (`{ts, hook, pattern, session_id}`) to `~/.claude/fable-mode/telemetry.jsonl` (fail-open, no PII beyond session id). `/fable-status` and the eval report read it, so real-session drift feeds the tuning loop, not just synthetic probes.

### C3. Skills — `skills/`

Skills are the habit-forming layer (hooks are the backstop). All three carry aggressive trigger descriptions, and the SessionStart card advertises them (the superpowers enforcement pattern, proven to work).

1. **`fable-voice`** — "Use when about to write your final reply, a summary, PR description, or commit message." The communication contract as a short checklist plus **bad→good worked examples** (header-spam answer → prose answer; process-narration → outcome-first; hedged claim → plain claim; arrow-chain → sentence). Examples are the teeth — models imitate examples better than rules.
2. **`fable-fanout`** — "Use when a task has 2+ independent units of work or requires a broad codebase sweep." Decision tree: single known-location lookup → direct tool; broad/multi-file question → delegate to the built-in `Explore` agent type (fallback `general-purpose` if unavailable); 2+ independent units → spawn agents **in one message**; worktree isolation when agents mutate files; synthesis step owns the final answer. This is Workflow-lite doctrine for the standard Agent tool. Because subagents never see the output style, the skill ships a **required subagent prompt template** that propagates doctrine into every spawn: "Return conclusions, not file dumps. Report failures verbatim. Your final text is the return value — raw findings, not a human-facing message."
3. **`fable-turn-check`** — "Use before ending any turn that involved multi-step work." The end-of-turn checklist mirroring the Stop-gate (so the model internalizes the rule before the hook fires): last paragraph a promise? → do it; unreported failures? → report verbatim; important findings buried mid-turn? → restate in final message.

Composition rule stated in each SKILL.md: superpowers owns brainstorming/TDD/debugging/verification; playbook skills own voice, orchestration shape, and turn-end discipline.

### C4. Agents — `agents/critic.md`

One agent, lean: **critic** — adversarial verifier. Given a claim, diff, or finding, it attempts to *refute* it and reports CONFIRMED / REFUTED with evidence. Used by `fable-turn-check` before big "it's done" claims and by the eval judge pipeline. Model: default (inherits session); tools: read-only + Bash for running tests. We deliberately do not ship a search agent — current Claude Code builds ship a built-in `Explore` type; `fable-fanout` references it with a documented fallback.

### C5. Settings profile — `profiles/opus-fable.settings.json` (documented, not auto-shipped)

Plugins cannot ship model/outputStyle/env settings, so the README carries a copy-paste profile:

```json
{
  "model": "claude-opus-4-8",
  "effortLevel": "xhigh",
  "alwaysThinkingEnabled": true,
  "outputStyle": "Fable"
}
```

Notes: effort levels verified to apply to Opus 4.8 (default `high`; we pin `xhigh`). The `[1m]` model-suffix and `MAX_THINKING_TOKENS` are unverified for Opus 4.8 — the profile uses the plain model id and no thinking env var. For SDK/headless embedding, `--append-system-prompt "$(cat output-styles/fable.md)"` is the equivalent channel (documented in README).

### C6. Eval harness — `evals/`

Turns "be like Fable" from vibes into numbers, and closes the loop.

- **`probes/`** — 12 prompt scenarios, ≥1 per spine row plus combos. Examples: a vague bug report (must assess, not fix); a 3-module refactor (must parallelize); a failing-test fixture (must report output verbatim); a one-line question (must answer in prose, no headers); a long multi-step task (must not stop early); a "clean up this file" task (comment discipline). Small fixture repos under `evals/fixtures/` where needed; runs capped with `--max-turns`.
- **`golden/`** — Fable 5 transcripts for every probe, generated once (`--model claude-fable-5`), stored as reference behavior. Captures Fable habits the doctrine can't fully articulate.
- **`rubric.md`** — 8 dimensions scored 0–2: outcome-first, no-burial, turn-completion, autonomy calibration, honesty, delegation/parallelism, tool discipline, code-comment discipline.
- **`run-probe.sh`** — runs one probe headless: `claude -p "$(cat probe)" --model <m> --output-format json`; saves transcript JSON. **Isolation (amended 2026-07-02):** `--bare` requires an API key and breaks OAuth/subscription auth, so isolation instead uses a generated settings file that disables every user-enabled plugin (`evals/lib/isolation.py`, verified working under OAuth). Baseline and golden runs get the disable map alone; the playbook candidate gets the map merged with the profile, plus `--plugin-dir <repo>` so ONLY fable-mode loads — keeping the A/B symmetric. Residual shared contamination (user CLAUDE.md) hits both arms equally.
- **`judge.sh`** — **pairwise judging** (more reliable than absolute scores): judge model receives candidate transcript + golden transcript + rubric → per-dimension scores + "which is closer to golden" verdict, as JSON. Judge model configurable; default a strong non-candidate model.
- **`report.sh`** — aggregates into one table: vanilla Opus vs fable-mode Opus vs golden, per dimension.
- **`LOOP.md`** — the distillation procedure: low-scoring dimension → strengthen exactly that doctrine section / hook / example → re-run probes → compare. Inputs are both synthetic (probe scores) and real (hook telemetry counts). Every accepted tuning iteration bumps the plugin version with a CHANGELOG entry so doctrine evolution is traceable. Manual in v1 (automating doctrine-patch proposals is a future idea).
- **`/fable-eval` command** — runs the probe suite + report from inside a session (wraps the scripts), so tuning doesn't require leaving Claude Code.

### C7. Packaging — plugin repo layout

```
opus-fable-playbook/
├── .claude-plugin/plugin.json      # name: fable-mode, version 0.1.0, metadata
├── output-styles/fable.md          # C1
├── hooks/hooks.json                # C2 wiring
├── hooks/*.sh, hooks/lib/*.py      # C2 scripts (fail-open, tested)
├── skills/fable-voice/SKILL.md
├── skills/fable-fanout/SKILL.md
├── skills/fable-turn-check/SKILL.md
├── agents/critic.md                # C4
├── commands/fable-status.md        # /fable-status: posture report (style active? hooks live? settings drift? telemetry counts)
├── commands/fable-eval.md          # /fable-eval: run probe suite + report in-session
├── .github/workflows/ci.yml        # hook tests + shellcheck + plugin smoke on push/PR
├── profiles/opus-fable.settings.json
├── docs/claude-md-snippet.md       # doctrine card for CLAUDE.md, for people who won't install a plugin
├── evals/…                         # C6
├── tests/hooks/…                   # canned-stdin hook tests
├── docs/superpowers/specs/…        # this spec
└── README.md                       # install (marketplace / --plugin-dir), activation, strict mode, eval loop
```

Distribution: works immediately via `claude --plugin-dir`; installable from GitHub once pushed; later listed in the user's `rennf93` marketplace. This repo is its own git repository (ZZZ is a container of personal projects, not a repo).

## 5. Phasing

- **P1 — Doctrine (usable day one):** plugin skeleton, output style, doctrine card + CLAUDE.md snippet, settings profile, README.
- **P2 — Enforcement:** hooks + hook tests, three skills, critic agent, `/fable-status` command.
- **P3 — Convergence:** probes + fixtures, golden Fable transcripts, judge + report, first tuning iteration documented in LOOP.md.

## 6. Testing strategy

- **Hooks:** pure-function tests — canned stdin JSON + transcript fixtures → assert exit code and stdout decision. Runnable with a plain `tests/run.sh` (no framework). Cases: promise-ending blocks; question-ending passes; `stop_hook_active` passes; malformed JSON fails open; bash-discipline denies `cat file`, passes `cat file | wc -l`; honesty-nudge fires on pytest/jest/cargo/go failure fixtures, silent on passes.
- **False-positive calibration:** the golden Fable transcripts double as a stop-gate fixture set — if a tier-1 pattern would block any of Fable's own turn endings, the pattern is miscalibrated and the test fails. Zero-cost, high-signal.
- **CI:** GitHub Actions on push/PR — `tests/run.sh`, `shellcheck hooks/*.sh`, and a plugin structural check (manifest parses, referenced files exist).
- **Skills/style:** exercised by the eval probes (before/after comparison is the test).
- **Whole-plugin smoke:** `claude -p --plugin-dir . "smoke prompt"` in CI-able script.

## 7. Risks and mitigations

1. **Output style replaces defaults** → `keep-coding-instructions: true`, verified against docs.
2. **Conflict with superpowers** (skill-first, interactive brainstorming vs autonomy doctrine) → explicit precedence clause in C1(7); playbook never duplicates superpowers domains.
3. **Stop-gate false positives** → conservative promise-only patterns; question-endings exempt; single-block semantics guarantee at most one forced continuation.
4. **Hook overhead** → tier-1 deterministic (<100ms, ~30–50 tokens/prompt injected); LLM judge strictly opt-in.
5. **Opus ignores skills** → SessionStart card advertises triggers (superpowers-proven pattern).
6. **Judge bias** → pairwise-vs-golden instead of absolute scoring; judge model configurable.
7. **Unverified model knobs** (`[1m]` suffix, `MAX_THINKING_TOKENS` on Opus 4.8) → excluded from profile; noted in README.
8. **Unverified hook contracts** (PostToolUse `additionalContext`, PreCompact injection shape) → re-verify against docs at implementation; both hooks are additive-only, so a contract mismatch degrades to a no-op, never to breakage.
9. **Cross-platform** → hooks are bash+python3 (macOS/Linux native; Windows via WSL/Git-Bash, untested in v1 — README disclaimer).

## 8. Assumptions taken while user was away (please veto/adjust)

- **A1:** All four behavior clusters in scope (communication, turn discipline/autonomy, delegation/parallelism, rigor/honesty).
- **A2:** Deliverable is a plugin repo in `opus-fable-playbook/`, eventually listed on the `rennf93` marketplace; standalone `--plugin-dir` use works meanwhile.
- **A3:** Deterministic hooks on by default; LLM stop-judge opt-in via `FABLE_STOP_JUDGE=1`.
- **A4:** Eval harness is in scope (phase 3).
- **A5:** No CLAUDE.md changes are auto-applied by the plugin; the snippet is offered as an optional copy-paste.

## 9. Future ideas (explicitly out of scope for v1)

- Auto-distillation: script that diffs candidate vs golden transcripts and proposes doctrine patches.
- Judge tier default-on with caching.
- Statusline "FABLE-MODE" indicator.
- Shadow-judging real sessions (LLM-scoring live transcripts against the rubric, not just probes).
- Per-pattern circuit breaker: if the same hook pattern fires N times in a window, escalate the message ("stop and ask the user") instead of repeating it (idea validated by roboco's per-verb breaker, `agent_loop.py`).
- Deterministic evidence table for "done" claims: verb→required-evidence mapping (tests run since last edit, diff reviewed) checked by the stop-gate, adapted from roboco's `tracing.py` pattern.

**Design conventions adopted from roboco review (2026-07-02):** every hook block/deny message states the violation AND the literal next action (roboco's `remediate` contract); `/fable-status` frames telemetry as an enforcement-tax report (how often gates fired ≈ what drift they caught).
