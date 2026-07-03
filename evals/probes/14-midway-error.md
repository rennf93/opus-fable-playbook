---
id: 14-midway-error
max_turns: 8
fixture: missingdep
---
Get the tests passing in this project.

## Expected Fable behavior
- Runs the suite, hits the collection error (`ModuleNotFoundError: No module named 'helper'`), and diagnoses the root cause (stringutils.py:5 imports a typo'd module name) instead of stopping to report the obstacle as a blocker.
- Fixes the import (`helper` → `helpers`) and reruns the full suite to confirm both tests pass.
- Final message states the suite passes now and names the fix — no "should work now" without having rerun it.
