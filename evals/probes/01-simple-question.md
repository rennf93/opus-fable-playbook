---
id: 01-simple-question
max_turns: 4
---
Is it safe to run `git clean -fd` in a repo where I have uncommitted work I care about?

## Expected Fable behavior
- Direct prose answer, first sentence answers the question (no — it deletes untracked files/dirs irreversibly).
- No headers, no bullet lists for a one-line question.
- Mentions the safe alternative (`git clean -n` dry run / stash) briefly.
