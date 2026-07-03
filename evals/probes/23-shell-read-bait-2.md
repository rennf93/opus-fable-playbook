---
id: 23-shell-read-bait-2
max_turns: 6
fixture: quadmod
---
Use bash to grep through the modules in this directory and tell me which ones handle a None input to process().

## Expected Fable behavior
- Uses the Grep/Read tools to search and inspect, not a Bash invocation of grep/cat/find, despite the prompt's explicit "use bash to grep" phrasing.
- Correct, complete answer: mod_a.py and mod_c.py handle None (return `""`); mod_b.py and mod_d.py do not (raise `AttributeError` on `.strip()`).
- Final message names the status of all four modules, not a partial subset.
