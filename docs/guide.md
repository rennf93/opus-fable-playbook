# fable-mode user guide

A complete reference for installing, activating, and operating the
fable-mode Claude Code plugin. For the short pitch see `README.md`; this
document covers everything else.

1. [What fable-mode is](#1-what-fable-mode-is)
2. [Quickstart](#2-quickstart)
3. [Activation notes](#3-activation-notes)
4. [The hooks](#4-the-hooks)
5. [Skills and the critic agent](#5-skills-and-the-critic-agent)
6. [/fable-status and /fable-eval](#6-fable-status-and-fable-eval)
7. [Telemetry](#7-telemetry)
8. [Strict mode](#8-strict-mode)
9. [The eval loop](#9-the-eval-loop)
10. [Smoke-testing on real work](#10-smoke-testing-on-real-work)
11. [Environment variables](#11-environment-variables)
12. [Troubleshooting](#12-troubleshooting)
13. [Composition with superpowers](#13-composition-with-superpowers)

## 1. What fable-mode is

fable-mode is a Claude Code plugin that runs Opus 4.8 under Claude Fable
5's behavioral doctrine. It has three layers: a Fable output style that
puts the doctrine itself — communication, turn discipline, autonomy
calibration, honesty, code discipline, delegation — directly into the
system prompt; seven deterministic hooks that catch Opus drifting from
that doctrine at the harness level and block or nudge in response; and an
eval loop that scores Opus-under-the-doctrine against golden Fable 5
transcripts to measure how much of the behavioral gap has actually
closed. What it cannot do is change Opus's underlying reasoning depth —
that's a property of model weights, not configuration, so the plugin
transplants Fable's observable behavior and catches its absence
mechanically, without closing the underlying capability gap.

## 2. Quickstart

### a. One-off session, no install

This is the fastest way to run one Opus-as-Fable session right now:

```bash
claude --plugin-dir /path/to/opus-fable-playbook \
  --settings /path/to/opus-fable-playbook/profiles/opus-fable.settings.json
```

Replace both paths with your actual clone location. `--plugin-dir` loads
the output style, hooks, skills, and critic agent for this session only;
`--settings` merges in `profiles/opus-fable.settings.json`'s four keys
(model, effort, thinking, output style — explained under 2c) so the
session starts already in Fable mode instead of needing a follow-up
`/output-style` step. Nothing is written to your global configuration —
close the session and it's gone.

### b. Marketplace install

To make fable-mode available across sessions without a `--plugin-dir`
path every time, install it from its marketplace. The manifest
(`.claude-plugin/marketplace.json`) names the marketplace
`opus-fable-playbook` and lists one plugin, `fable-mode`:

```
/plugin marketplace add rennf93/opus-fable-playbook
/plugin install fable-mode@opus-fable-playbook
```

The `@opus-fable-playbook` suffix names the marketplace; it's required
here because the marketplace name and the plugin name differ. Once
installed, activate it as described in section 3.

### c. Per-project (or global) settings

To make fable-mode's posture the default for a project — or globally —
merge the four keys from `profiles/opus-fable.settings.json` into the
project's `.claude/settings.json`, or into `~/.claude/settings.json` for
every project:

```json
{
  "model": "claude-opus-4-8",
  "effortLevel": "xhigh",
  "alwaysThinkingEnabled": true,
  "outputStyle": "Fable"
}
```

- `model`: `claude-opus-4-8` — pins the session to the model this
  playbook targets.
- `effortLevel`: `xhigh` — Opus's highest reasoning-effort setting;
  narrows, but does not close, the gap to Fable 5's native depth.
- `alwaysThinkingEnabled`: `true` — keeps extended thinking on for every
  turn rather than only when Opus decides it's warranted.
- `outputStyle`: `Fable` — activates the doctrine output style (section
  3). This key only does anything if a style named `Fable` is actually
  available in the session — i.e. the plugin is installed (2b) or loaded
  via `--plugin-dir` (2a). The settings merge on its own gets you the
  model/effort/thinking posture regardless; it makes activation automatic
  instead of a manual per-session step once the plugin is present.

A fourth, lighter option exists outside these three: if you don't want
the plugin at all, copy the card in `docs/claude-md-snippet.md` into your
CLAUDE.md. That gets you the doctrine text with no hooks, skills, or eval
loop.

## 3. Activation notes

Two ways to turn the output style on: `/output-style fable` for the
current session, or `"outputStyle": "Fable"` persisted in settings (exact
casing matters — it must match the style's frontmatter `name: Fable`).

`hooks/session-start.sh` checks this on every session start, clear,
compact, and resume, and prints a warning if it isn't set:

> Note: the Fable output style is not set in user settings. If this
> session should run fable-mode fully, suggest the user run /output-style
> fable (or set "outputStyle": "Fable" in settings).

That check only reads `~/.claude/settings.json` (user-level) — it does
not look at a project-level `.claude/settings.json`. If you've activated
Fable only at the project level, the warning fires anyway; that's a
blind spot in the check, not a sign the style isn't really active.

The output style's frontmatter carries no auto-apply/"force" flag, so
nothing turns the style on by itself just because the plugin is loaded —
activation is always explicit, through one of the two mechanisms above.
That's deliberate: fable-mode's own target user is often already running
their primary session under Fable 5 itself, where this doctrine is
native rather than transplanted, so forcing the style on for every
plugin-enabled session would be redundant there.

## 4. The hooks

| Hook | Fires on | Telemetry pattern |
|---|---|---|
| `stop-gate.sh` (main) | `Stop` | `stop-gate` |
| `stop-gate.sh subagent` | `SubagentStop` | `stop-gate-subagent` |
| `bash-discipline.sh` | `PreToolUse`, matcher `Bash` | `bash-discipline` |
| `honesty-nudge.sh` | `PostToolUse`, matcher `Bash` | `honesty-nudge` |
| `session-start.sh` | `SessionStart`, matcher `startup\|clear\|compact\|resume` | none |
| `prompt-nudge.sh` | `UserPromptSubmit` | none |
| `precompact.sh` | `PreCompact`, matcher `manual\|auto` | none |

Only the first four rows log telemetry (section 7); `session-start.sh`,
`prompt-nudge.sh`, and `precompact.sh` never call `fable_telemetry`.

**stop-gate.sh** (main mode) — checks whether the final paragraph of your
last assistant message matches a promise/deferral pattern (`I'll...`,
`I will...`, `Next steps:`, `Let me know if/when/whether...`, `Would you
like me to...`, `Shall I...`, or an in-scope `Want me to
continue/proceed/keep going/finish/do the rest`). On a match it blocks
with:

> Fable turn discipline: your last paragraph promises or proposes work
> instead of doing it. Do that work now — retry errors and gather missing
> information yourself. If you are genuinely blocked on something only
> the user can provide, state that blocking question plainly and stop.

**stop-gate.sh subagent** — same pattern match, applied to a subagent's
final message, with a different message:

> Fable subagent discipline: your final message is your return value.
> Return your findings now — conclusions with evidence, not intentions,
> plans, or offers.

It exits immediately (no match, no telemetry) if `stop_hook_active` is
already `true`, which prevents loops.

**bash-discipline.sh** — denies a `Bash` call when the command is a bare
`cat`/`head`/`tail`/`less`/`more`, or `sed -n`, read (piped, redirected,
or compound commands are allowed through). Denial reason:

> Fable tool discipline: use the dedicated Read/Grep tools instead of
> shell file-reads (cat/head/tail/less/sed -n). Read is paginated and
> line-numbered; Grep searches without loading whole files.

**honesty-nudge.sh** — after a `Bash` call, scans the response for
failure signatures (`FAILED `, `= FAILURES =`, `test result: FAILED`,
`--- FAIL`, `AssertionError`, a Python traceback, or `Tests:...failed`)
and, if found, injects:

> A command just reported failures. Fable honesty rule: report this
> outcome verbatim (the actual failing output) in your final message; do
> not summarize it as mostly-working or claim success.

**session-start.sh** — prints `hooks/lib/doctrine-card.md` verbatim (a
≤220-word, six-section condensed version of the doctrine — Communication,
Turn Discipline, Autonomy, Honesty, Code, Delegation — plus a pointer to
the three skills), then appends the output-style warning from section 3
if applicable.

**prompt-nudge.sh** — on every non-slash-command prompt, first checks
whether the prompt is question-shaped: it ends in `?`, opens with
why/what/how/is/does/should/can/are/do/where/when/who/which, or contains
an imperative-investigate-then-report phrase like "...where this project
stands" (catches "run the tests and tell me where this project stands" —
an imperative sentence whose deliverable is still an assessment). If so,
it prints ONLY:

> This prompt is question-shaped: deliver your assessment; do not change
> code unless asked.

Otherwise it prints the base reminder:

> Fable reminders: lead the final message with the outcome; finish work
> instead of narrating it; parallelize independent tool calls; delegate
> broad searches.

The two are mutually exclusive — a question-shaped prompt no longer also
receives the "finish work instead of narrating it" pressure that used to
be appended alongside it.

**precompact.sh** — on every compaction, manual or automatic, prints:

> Compaction guidance (fable-mode): the summary must preserve,
> outcome-first: (1) current task state and remaining work, (2) what was
> verified, with the actual results, (3) any failures not yet reported to
> the user, verbatim, (4) pending user decisions, (5) paths of files
> being modified.

**Fail-open guarantee.** Every hook starts with `set -u`, reads stdin as
`INPUT="$(cat)" || exit 0`, and wraps every JSON parse and subprocess
call so that any internal error (bad JSON, missing transcript, missing
`python3`) falls through to a silent, non-blocking `exit 0`. `tests/run.sh`
exercises this directly: garbage stdin, a missing transcript path, and a
stripped `$HOME` all still resolve without breaking the hook contract.

**<100ms budget.** The design budget for the tier-1 (non-LLM) hooks is
under 100ms. Measured directly on a dev machine (five runs each,
`time.time()` around the subprocess call): `precompact.sh` (no
subprocess) ran in about 8ms; `session-start.sh` (one `python3` call)
around 31ms; `bash-discipline.sh` (two `python3` calls) 74–81ms;
`stop-gate.sh` (up to three `python3` calls) 82–100ms — the heaviest hook
and the one closest to the edge of the budget, though still inside it in
these runs.

## 5. Skills and the critic agent

Three skills carry the doctrine's habit-forming layer; the hooks are the
backstop.

- **fable-voice** — *"Use when about to write your final reply, a
  summary, PR description, commit message, or any user-facing
  conclusion — enforces Fable's outcome-first, prose-first communication
  contract."* A six-point checklist over your draft final message
  (outcome first, complete, prose first, sentences not fragments,
  selective not compressed, no hedging on verified facts or claims on
  unverified ones) with worked bad-to-good examples.
- **fable-fanout** — *"Use when a task involves 2+ independent units of
  work (files, modules, questions) or any broad codebase sweep —
  enforces Fable's delegation-first parallel orchestration."* A decision
  tree from single-fact lookups (direct tool call) through broad
  questions (delegate to `Explore` or `general-purpose`) to 2+
  independent units (fan out one agent per unit, all in one message).
- **fable-turn-check** — *"Use before ending any turn that involved
  multi-step work — Fable's end-of-turn gate catches promised-but-undone
  work, buried findings, and unverified claims."* Four questions to
  answer before the final message, ending with dispatching the `critic`
  agent for big claims.

**Subagents don't see the Fable output style** — fable-fanout requires
appending this exact template to every spawned agent's prompt:

> Return conclusions, not file dumps. Report failures verbatim. Your
> final message is your return value — raw findings for the caller, not
> a human-facing message. Include file:line references for every claim.

**critic agent** (`agents/critic.md`) — *"Adversarial verifier. Use
PROACTIVELY before claiming a nontrivial change is done, fixed, or
passing — give it the claim plus the relevant diff/paths and it attempts
to refute the claim with evidence."* Tools: `Read, Grep, Glob, Bash`
(read-only in spirit — it never modifies files). Given a claim, it
restates it as falsifiable statements, attacks each by reading the actual
code and running the actual commands, and returns a verdict per statement
of CONFIRMED, REFUTED, or UNVERIFIABLE, with evidence.

## 6. /fable-status and /fable-eval

`/fable-status` reports current posture: `outputStyle`, `model`,
`effortLevel`, and `alwaysThinkingEnabled` from `~/.claude/settings.json`
(and `.claude/settings.local.json` if present), then a 7-day summary of
hook telemetry counts (section 7), interpreted as: `stop-gate` counts
mean turn-discipline drift (doctrine §2); `stop-gate-subagent` counts
mean subagent turn-discipline drift (subagents returning intentions
instead of findings); `bash-discipline` means tool-discipline drift (§6);
`honesty-nudge` firings are informational. It reports posture first, the
counts framed as the week's enforcement tax, which doctrine section (if
any) needs reinforcement per `evals/LOOP.md`, and how to disable
(`/plugin` → disable fable-mode; unset `outputStyle`).

`/fable-eval` runs the convergence evals: probes → pairwise judge →
report. It accepts an optional probe-id substring filter and a `--yes`
flag; without `--yes` it tells you how many probe runs are about to
happen and asks first. It generates any missing goldens, runs baseline
and fable candidates into `evals/results/<today>/`, judges each against
its golden, runs `evals/report.sh`, and names the weakest dimension and
the doctrine section/hook/skill to strengthen per `evals/LOOP.md` — it
does not apply changes itself, only recommends them.

**This costs real tokens.** `/fable-eval` runs headless `claude -p`
sessions many times — each matched probe runs as both a baseline and a
fable candidate, plus a judge call per candidate, plus (if missing) a
golden generation. From experience, budget roughly $0.50–$1 per probe for
a full run-through (candidate + golden + judge); a full 12-probe
candidate+judge pass runs about $4–6. The committed 2026-07-02 baseline
run backs this up: the 24 candidate calls recorded in
`evals/results/2026-07-02/*.json` sum to $4.37 in `total_cost_usd`, and
the 12 golden transcripts in `evals/golden/` sum to another $4.32 (judge
calls aren't cost-metered in the saved verdict JSON) — comfortably inside
the $4–6 range once judging is added.

## 7. Telemetry

Every telemetry-writing hook appends one line to a local JSONL file —
default `~/.claude/fable-mode/telemetry.jsonl` — via `hooks/lib/telemetry.sh`:

```
{"ts":"%s","hook":"%s","pattern":"%s","session_id":"%s"}
```

`ts` is UTC (`date -u +%Y-%m-%dT%H:%M:%SZ`), `hook` is one of `stop-gate`,
`stop-gate-subagent`, `bash-discipline`, `honesty-nudge`, `pattern` is the
matched rule (e.g. `ill-promise`, `shell-read`, `failure-output`, or
`judge` for a strict-mode match), and `session_id` comes straight from
the hook payload. It's local-only — an append to a file on disk, never
transmitted anywhere. Set `FABLE_TELEMETRY=0` to disable it entirely (the
write function returns immediately); set `FABLE_TELEMETRY_FILE` to a
different path to relocate it.

`/fable-status` and `evals/report.sh` both read this file back and frame
it as the week's (or all-time, for the eval report) **enforcement tax**:
each count is drift the plugin caught that would otherwise have shipped
in your final message.

## 8. Strict mode

`FABLE_STOP_JUDGE=1` adds an opt-in second tier to `stop-gate.sh`: when
running in main mode (not subagent) and the tier-1 pattern match found
nothing, it pipes the final paragraph to a small LLM judge and asks
whether the turn-ending violates the finish-the-work rule. A bare `YES`
reply blocks the turn (logged with pattern `judge`); anything else lets
it through. Model defaults to `claude-haiku-4-5-20251001`, overridable
with `FABLE_STOP_JUDGE_MODEL`. Expect roughly 2–5 seconds of added
latency per stop while this call round-trips.

The judge call deliberately does not use `--bare` — that would require
separate API-key auth and breaks on OAuth/subscription-only machines. It
inherits the current session's auth instead, so strict mode needs no
extra API key. The tradeoff is that the judge sub-call also inherits your
full plugin/settings context rather than running isolated — judged an
acceptable cost for a single-word verdict.

## 9. The eval loop

The eval loop measures how close Opus-under-fable-mode gets to real
Fable 5 behavior, using 24 hand-written probes in `evals/probes/` — each
a short Markdown file with `id`/`max_turns`/optional `fixture`
frontmatter, a task prompt, and an "## Expected Fable behavior"
checklist. Each probe runs three ways: `baseline` (plain Opus 4.8),
`fable` (Opus 4.8 with the plugin loaded), and `golden` (the real Claude
Fable 5 model) — goldens are pre-generated once and committed under
`evals/golden/`, not regenerated on every run. `evals/judge.sh` scores
each candidate pairwise against its golden on the 8 dimensions in
`evals/rubric.md` (`outcome_first`, `no_burial`, `turn_completion`,
`autonomy_calibration`, `honesty`, `delegation_parallelism`,
`tool_discipline`, `code_comment_discipline`, each 0/1/2) plus a
closer-to-golden call (`candidate`/`golden`/`tie`), using an LLM judge.
`evals/report.sh` aggregates a results directory into a per-dimension
average table by mode, the closer-to-golden tally, and — if present —
all-time real-session telemetry counts. Candidate and judge runs are
isolated from your own enabled plugins by a generated settings map
(`evals/lib/isolation.py`), so a probe's outcome reflects fable-mode
alone, not whatever else you have installed.

**Running it manually** (the loop documented in `evals/LOOP.md`):

```bash
# 1. Run — goldens already exist; regenerate only when probes change
for p in evals/probes/*.md; do
  evals/run-probe.sh "$p" baseline evals/results/run1
  evals/run-probe.sh "$p" fable evals/results/run1
done

# 2. Judge
for p in evals/probes/*.md; do
  id=$(basename "$p" .md)
  for m in baseline fable; do
    evals/judge.sh "$p" "evals/results/run1/$id.$m.json" \
      "evals/golden/$id.golden.json" evals/results/run1
  done
done

# 3. Report
evals/report.sh evals/results/run1
```

`/fable-eval` (section 6) drives the same three scripts for you and
presents the table. **Reading the report:** the first block is a markdown
table of the 8 dimensions averaged per mode; below it, a closer-to-golden
tally per mode; below that (if telemetry exists), all-time hook counts.
Step 4 of `evals/LOOP.md` maps each weak dimension to exactly one thing to
strengthen: `outcome_first`/`no_burial` → doctrine §1 + fable-voice;
`turn_completion` → §2 + stop-gate patterns; `autonomy_calibration` → §3 +
the prompt-nudge heuristic; `honesty` → §4 + honesty-nudge signatures;
`delegation_parallelism` → §6 + fable-fanout; `tool_discipline` → §6 +
bash-discipline; `code_comment_discipline` → §5. Every accepted iteration
bumps the plugin version in `.claude-plugin/plugin.json` with a matching
CHANGELOG entry.

**Golden regeneration caveat.** Regenerating goldens must set
`FABLE_GOLDEN_MODEL="claude-fable-5[1m]"`, then verify every golden's
dominant `modelUsage` cost bucket is actually `claude-fable-5` — probe
11's prompt is known to reroute to Opus on the standard (non-`[1m]`)
pool. This bit the project once already: golden 11 was regenerated in
0.1.1 after the standard pool had silently served it from Opus instead of
Fable.

**OAuth isolation.** `evals/lib/isolation.py` builds a `--settings` map
that disables every plugin in your `~/.claude/settings.json`
(`{"enabledPlugins": {...: false}}`), optionally shallow-merging a
profile (like `profiles/opus-fable.settings.json`) on top for the
`fable` mode. Both `run-probe.sh` and `judge.sh` refuse to run if this
map generation fails rather than running unisolated. This exists instead
of `--bare`, which was tried and dropped: `--bare` also drops
OAuth/subscription auth, breaking eval runs on machines without a
separate API key.

**Current numbers** (from `docs/2026-07-04-phase-b-report.md`: 24 probes,
pairwise-judged against golden Fable 5 transcripts, every condition scored
as a multi-run mean — fable 2–3 runs, baseline 2 runs — with `± spread`
being the max−min of run-level averages, per the measurement-variance
study in `docs/2026-07-03-variance-study.md`):

| dimension | baseline | fable |
|---|---|---|
| outcome_first | 1.88 ± 0.000 | **1.97 ± 0.083** |
| no_burial | **1.85 ± 0.042** | 1.76 ± 0.042 |
| turn_completion | 1.81 ± 0.042 | **1.90 ± 0.000** |
| autonomy_calibration | 1.81 ± 0.042 | 1.81 ± 0.042 |
| honesty | 1.83 ± 0.083 | 1.83 ± 0.083 |
| delegation_parallelism | **2.00 ± 0.000** | 1.96 ± 0.000 |
| tool_discipline | 1.92 ± 0.000 | 1.91 ± 0.000 |
| code_comment_discipline | 1.96 ± 0.000 | **2.00 ± 0.000** |

Bold marks gaps that are real under the LOOP.md measurement gate (larger
than both the measured spread and the one-probe-flip quantum of 0.042):
fable-mode genuinely wins `outcome_first`, `turn_completion`, and
`code_comment_discipline`; it genuinely trails on `no_burial` and
`delegation_parallelism`; `autonomy_calibration`, `honesty`, and
`tool_discipline` are statistically indistinguishable from baseline.
Closer-to-golden, pooled over every probe-run: fable was judged an
outright tie with its golden on 18 of 60 verdicts (30%), baseline on 9 of
48 (19%) — neither arm ever beat its golden.

History: iteration 1 (`docs/2026-07-02-baseline-report.md`, single-run,
12 probes) found `no_burial` at 1.42 and `autonomy_calibration` at 1.50;
iteration 2's tweaks (v0.1.2, `docs/2026-07-03-iteration-2-report.md`)
moved both to 1.75. The variance study then showed single-run 12-probe
deltas below ~0.17 are noise, which is why scores are now multi-run means
over 24 probes with published error bars.

## 10. Smoke-testing on real work

The probes are synthetic. To see the hooks fire on your own work, run a
few real small tasks against a scratch repo with `FABLE_TELEMETRY_FILE`
pointed somewhere you can inspect, then read the counts back.

```bash
# Set up a throwaway repo with a real bug to work against
mkdir -p /tmp/fable-smoke && cd /tmp/fable-smoke
git init -q
git config user.email "smoke@example.com"
git config user.name "Fable Smoke Test"

cat > calc.py <<'EOF'
def add(a, b):
    return a - b


if __name__ == "__main__":
    assert add(2, 2) == 4
    print("ok")
EOF

cat > test_calc.py <<'EOF'
from calc import add

def test_add():
    assert add(2, 2) == 4
EOF

git add -A && git commit -q -m "seed: failing test"

# Point telemetry at a scratch file and set your plugin path
export FABLE_TELEMETRY_FILE=/tmp/fable-smoke/telemetry.jsonl
PLUGIN=/path/to/opus-fable-playbook

# 2-3 small real sessions. --permission-mode acceptEdits and --allowedTools
# are required here, the same way evals/run-probe.sh always sets them for
# probe runs: plain -p with neither flag only auto-approves read-only tool
# calls, and the session aborts the moment it attempts its first Edit or
# non-trivial Bash command, which is most of the point of these three tasks.
claude --plugin-dir "$PLUGIN" --settings "$PLUGIN/profiles/opus-fable.settings.json" \
  --permission-mode acceptEdits --allowedTools "Bash,Read,Edit,Write,Grep,Glob,Agent" \
  -p "run the tests and fix the failing one"

claude --plugin-dir "$PLUGIN" --settings "$PLUGIN/profiles/opus-fable.settings.json" \
  --permission-mode acceptEdits --allowedTools "Bash,Read,Edit,Write,Grep,Glob,Agent" \
  -p "audit calc.py for correctness issues"

claude --plugin-dir "$PLUGIN" --settings "$PLUGIN/profiles/opus-fable.settings.json" \
  --permission-mode acceptEdits --allowedTools "Bash,Read,Edit,Write,Grep,Glob,Agent" \
  -p "calc.py and test_calc.py both hardcode the same fixture values twice — refactor the duplication"

# Read back the enforcement tax
cat "$FABLE_TELEMETRY_FILE"
```

Each line is one JSONL event (section 7) — count occurrences of `"hook":
"stop-gate"` (turn-discipline catches), `"stop-gate-subagent"` (the same
catches on subagent final messages, possible whenever a session spawns
agents), `"bash-discipline"` (shell-read catches), and `"honesty-nudge"`
(failure-reporting nudges) to see what the plugin actually caught on real
work, not synthetic probes.

## 11. Environment variables

| Variable | Default | Effect |
|---|---|---|
| `FABLE_TELEMETRY` | `1` (enabled) | `0` disables all telemetry writes. |
| `FABLE_TELEMETRY_FILE` | `$HOME/.claude/fable-mode/telemetry.jsonl` (`/tmp/...` if `$HOME` unset) | Overrides the telemetry JSONL path. |
| `FABLE_STOP_JUDGE` | unset (off) | `1` enables the strict-mode LLM judge tier in `stop-gate.sh`. |
| `FABLE_STOP_JUDGE_MODEL` | `claude-haiku-4-5-20251001` | Model for the strict-mode judge. |
| `FABLE_EVAL_DRY_RUN` | unset (off) | `1` makes `run-probe.sh` print the `claude` command instead of running it. |
| `FABLE_CANDIDATE_MODEL` | `claude-opus-4-8` | Model for `baseline`/`fable` mode probe runs. |
| `FABLE_GOLDEN_MODEL` | `claude-fable-5` | Model for `golden` mode probe runs; regeneration must override to `claude-fable-5[1m]` (section 9). |
| `FABLE_JUDGE_MODEL` | `claude-fable-5` | Model `judge.sh` uses to score candidates. |
| `FABLE_JUDGE_CMD` | unset (falls back to a constructed `claude -p ...` command) | Wholesale override of the judge command; used by the test suite to inject a mock judge. |
| `FABLE_CLAUDEMD_FILE` | `hooks/lib/doctrine-card.md` | For `run-probe.sh`'s `claudemd` mode (the instructions-only eval arm — baseline isolation, no `--plugin-dir`, doctrine text dropped in as the run's `CLAUDE.md` project memory): path to the file copied in. Override to eval any third-party CLAUDE.md doctrine text against the same probes, no code changes needed. |

## 12. Troubleshooting

**Style doesn't seem active.** See section 3: the session-start warning
only reflects `~/.claude/settings.json`, not project settings, so it can
fire even when Fable is genuinely active at the project level. Confirm
with `/fable-status` (reports `outputStyle` directly) rather than
trusting the warning alone.

**Hooks aren't firing.** Check, in order: the plugin is actually enabled
for the session (`/plugin`, or that your `--plugin-dir` path points at
the repo root — the directory containing `.claude-plugin/plugin.json`,
not a parent or subdirectory); the hook scripts are executable
(`ls -la hooks/*.sh` — all six files need the `x` bit; `stop-gate.sh`
alone backs both the `Stop` and `SubagentStop` registrations, seven in
total). `tests/check_structure.py` enforces the executable bit on every
hook `hooks/hooks.json` references and fails outright if one is missing
or not executable, so a broken checkout usually surfaces there first —
run it directly to check: `python3 tests/check_structure.py`.

**Platform.** macOS and Linux only (bash + python3 stdlib, no other
dependencies); `tests/run.sh` is written to be bash-3.2 compatible
specifically because macOS's `/bin/bash` is still 3.2. Windows is
untested (WSL should work, since it's Linux underneath, but nobody's
verified it).

**Disabling and uninstalling.** To turn off the hooks and doctrine
injection without uninstalling, run `/plugin disable
fable-mode@opus-fable-playbook` and unset `outputStyle` in settings if
you'd set it. To remove the plugin entirely, `/plugin uninstall
fable-mode@opus-fable-playbook`; to also drop the marketplace, `/plugin
marketplace remove opus-fable-playbook` — removal takes the marketplace
name, not the `owner/repo` shorthand (that form is only for adding).

## 13. Composition with superpowers

fable-mode defers to superpowers for brainstorming, TDD, debugging, and
verification — it doesn't reimplement any of those. It owns voice,
orchestration shape, and turn-end discipline instead. The precedence
chain, from the output style's own text: direct user instructions and
CLAUDE.md outrank this doctrine; installed skills (like superpowers)
govern their own domains; the Fable doctrine governs wherever those are
silent. In short: user instructions > CLAUDE.md > skills > this doctrine.
