# fable-mode

[![ci](https://github.com/rennf93/opus-fable-playbook/actions/workflows/ci.yml/badge.svg)](https://github.com/rennf93/opus-fable-playbook/actions/workflows/ci.yml)

Make Claude Opus 4.8 in Claude Code behave as much like Claude Fable 5 as
possible. The doctrine was transcribed by Fable 5 itself; hooks enforce
it at the harness level; an eval loop measures convergence against
golden Fable transcripts. Opus's reasoning depth is weights, not
config — this playbook transplants Fable's *behavior* and catches Opus's
drift mechanically; it does not close the capability gap.

## Quickstart

Run one Opus-as-Fable session right now, no install:

```bash
claude --plugin-dir /path/to/opus-fable-playbook \
  --settings /path/to/opus-fable-playbook/profiles/opus-fable.settings.json
```

Install from the marketplace for repeat use:

```
/plugin marketplace add rennf93/opus-fable-playbook
/plugin install fable-mode@opus-fable-playbook
```

then activate with `/output-style fable`, or persist it by merging
`profiles/opus-fable.settings.json` (model, effort, thinking, output
style) into your project's or user's `.claude/settings.json`. Check
posture anytime with `/fable-status`.

SDK/headless, doctrine text only, no hooks:
`--append-system-prompt "$(awk 'f;/^---$/{c++;if(c==2)f=1}' output-styles/fable.md)"` —
strips the YAML frontmatter (a plain `cat` of the file would leak it into
the prompt). No plugin at all? Copy `docs/claude-md-snippet.md` into
CLAUDE.md instead.

## Does it work?

Iteration 1's baseline eval (12 probes, pairwise-judged against golden
Fable 5 transcripts) shows real but mixed convergence: fable-mode wins
outcome-first framing and turn completion outright (2.00 vs baseline's
1.83) but currently trails baseline on burying findings and autonomy
calibration (1.42 and 1.50 vs 1.83 and 1.67). It's a net improvement on
some doctrine dimensions and a regression on others — which is what the
eval loop is for.

## Full documentation

**[`docs/guide.md`](docs/guide.md)** covers all of this in full:
activation details for each install method, the 7 hooks and the exact
messages they produce, the skills and the critic agent, `/fable-status`
and `/fable-eval` (including real eval costs), telemetry, strict mode,
the eval loop end to end, a copy-paste smoke-test recipe for real work,
every `FABLE_*` env var, and troubleshooting.
