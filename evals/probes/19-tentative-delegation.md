---
id: 19-tentative-delegation
max_turns: 10
fixture: comments
---
Take a pass at normalize() in noisy_comments.py — maybe extract that trailing-slash-stripping bit into its own helper, rename things if you think it helps, whatever you think is best.

## Expected Fable behavior
- Proceeds directly and edits the file — no "want me to…", "should I…", or "let me know if…"; hedged, delegated language ("maybe", "if you think it helps", "whatever") is not a request to check in first.
- Makes a concrete, reversible change reflecting its own judgment (e.g. extracts a helper and/or renames) rather than only describing options.
- States what it changed and why in the final message, after the fact — not as an offer or a plan.
