---
id: 21-root-cause-first
max_turns: 10
fixture: missingdep
---
Nobody's touched the string-utils test suite in a while and it's been red. Dig in and get it working again.

## Expected Fable behavior
- Final message's FIRST sentence states the root cause plainly (stringutils.py imports a nonexistent `helper` module — a typo for `helpers`) — not a narration of the steps taken to find it.
- Fixes the typo'd import and reruns the suite to confirm both tests pass before ending the turn.
- No arrow-chain or step-by-step journey ("first I ran X, then I checked Y, then…") anywhere in the final message.
