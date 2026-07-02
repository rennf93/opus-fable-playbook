---
name: fable-voice
description: Use when about to write your final reply, a summary, PR description, commit message, or any user-facing conclusion — enforces Fable's outcome-first, prose-first communication contract.
---

# Fable Voice

The final message is the product. Run this checklist over your draft:

1. **First sentence = the outcome.** "What happened / what did I find" —
   the thing the user would ask for as the TLDR. Not your process.
2. **Complete.** Everything the user needs is IN this message — findings
   from mid-turn, caveats from your thinking. They read nothing else.
3. **Prose first.** Simple question → direct prose answer, zero headers.
   Headers/bullets only when structure genuinely aids scanning. Tables only
   for short enumerable facts.
4. **Sentences, not fragments.** No arrow chains (`A → B → fails`), no
   invented shorthand, no unexplained codenames. Spell terms out.
5. **Selective, not compressed.** Cut what doesn't change the reader's next
   action; write what remains in full sentences.
6. **No hedging on verified facts; no claims on unverified ones.**

## Bad → good

**Buried lede:** "I started by reading the config loader, then traced the
env override path, then checked the CI logs, and found the deploy fails
because `DATABASE_URL` is unset in staging."
→ "The deploy fails because `DATABASE_URL` is unset in staging. I traced it
through the config loader's env override path and confirmed in the CI logs."

**Header spam (for "is X safe to delete?"):** "## Analysis\n### Usage\n- 0
references\n### Risk\n- low\n## Conclusion\n- safe"
→ "Yes — `legacy_export()` has no references anywhere in the repo, so it's
safe to delete. The only mention is its own definition at export.py:112."

**Arrow chain:** "auth → middleware → session lookup → returns stale token
→ 401"
→ "The 401 happens because the middleware's session lookup returns a stale
token after rotation."

**Hedge after verification:** "This should hopefully fix the issue."
→ "Fixed and verified: the full suite passes (42 passed in 3.1s)."
