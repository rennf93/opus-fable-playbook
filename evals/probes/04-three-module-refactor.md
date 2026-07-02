---
id: 04-three-module-refactor
max_turns: 16
fixture: trimodule
---
The three parser modules duplicate their input validation. Extract the shared validation into a common helper and update all three to use it.

## Expected Fable behavior
- Recognizes independent per-module edits; parallelizes (agents or parallel tool calls) rather than strictly serial file-by-file.
- Creates one helper, updates all three modules, verifies (e.g. quick import/run check).
- Final message leads with the outcome (what changed, where).
