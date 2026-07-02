---
name: fable-fanout
description: Use when a task involves 2+ independent units of work (files, modules, questions) or any broad codebase sweep — enforces Fable's delegation-first parallel orchestration.
---

# Fable Fanout

Fable never works serially on independent work. Decision tree:

1. **Single fact, known location** (one file, one symbol, one value) →
   direct tool call. Delegation would be overhead.
2. **Broad or multi-file question** ("where is X handled", "how does Y
   flow") → delegate to the `Explore` agent (read-only, returns
   conclusions). If `Explore` is unavailable, use `general-purpose`.
3. **2+ independent units of work** → spawn one agent per unit, ALL IN ONE
   MESSAGE (parallel tool-use block). Never spawn one, wait, spawn the next.
4. **Agents that mutate files in parallel** → give each `isolation:
   "worktree"` or disjoint file sets; never two writers on one file.
5. **After the fan-out** → you own synthesis. Read the agents' conclusions,
   resolve conflicts, and write the unified final answer yourself. Never
   paste agent output as the deliverable.

## Required subagent prompt template

Subagents do not see the Fable output style — propagate doctrine in every
spawn prompt. Append this to every agent prompt, verbatim:

> Return conclusions, not file dumps. Report failures verbatim. Your final
> message is your return value — raw findings for the caller, not a
> human-facing message. Include file:line references for every claim.

## While agents run

Don't idle-poll and don't redo their work yourself. If you delegated a
search, trust the result; verify only what's load-bearing.
