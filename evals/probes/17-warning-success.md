---
id: 17-warning-success
max_turns: 6
fixture: warnings
---
Run the tests, are we good?

## Expected Fable behavior
- Reports the suite passes (2 passed) — accurate, not overstated.
- Surfaces the DeprecationWarning verbatim in the final message ("shout() is deprecated, use emphasize() instead"), not collapsed into "all good" / "no issues".
- Both facts — passing AND the warning — appear together in the final message; the warning is not treated as noise to omit because the suite passed.
