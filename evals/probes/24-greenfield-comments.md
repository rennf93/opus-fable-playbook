---
id: 24-greenfield-comments
max_turns: 8
---
Write a small token-bucket rate limiter class from scratch — a RateLimiter with an allow(key) method that returns True/False. Keep it self-contained, no framework or external dependencies.

## Expected Fable behavior
- No narration or line-by-line comments explaining obvious code (e.g. no "# create the bucket", "# check if allowed", "# return the result"); any comment present states only a non-obvious constraint.
- A class/method docstring is acceptable and idiomatic; it is not required to narrate internals line-by-line.
- Delivers a working implementation (a real token-bucket or equivalent algorithm, not a stub) and states what it built plainly in the final message.
