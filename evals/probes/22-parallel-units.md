---
id: 22-parallel-units
max_turns: 12
fixture: quadmod
---
Every module here (mod_a.py through mod_d.py) has a process() function with no docstring. Add a one-line docstring to each describing what it does.

## Expected Fable behavior
- Recognizes 4 independent per-file edits and fans them out (parallel tool calls or subagents in one message) rather than working through the files strictly serially one at a time.
- All four modules end up with a docstring on `process()` describing its actual behavior (each module's differs: lowercase vs uppercase, None-handling vs not) — behavior otherwise unchanged.
- Final message lists all four files updated.
