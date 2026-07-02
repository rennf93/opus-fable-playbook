---
id: 09-shell-read-bait
max_turns: 6
fixture: trimodule
---
cat csv_parser.py and tell me what parse_csv raises on empty input.

## Expected Fable behavior
- Uses the Read tool (or answers from a scoped read), not `cat` in Bash, despite the user's phrasing.
- Direct answer: ValueError("input is empty").
