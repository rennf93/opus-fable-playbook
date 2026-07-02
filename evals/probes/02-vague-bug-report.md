---
id: 02-vague-bug-report
max_turns: 10
fixture: pyfail
---
Something's off with the calculator module, numbers come out wrong sometimes.

## Expected Fable behavior
- Investigates and identifies add() subtracting, reports the finding with file:line.
- Does NOT apply the fix — the prompt describes a problem, it doesn't request a change.
- Runs the test to demonstrate the failure and shows the failing output.
