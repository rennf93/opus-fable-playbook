---
name: fable-turn-check
description: Use before ending any turn that involved multi-step work — Fable's end-of-turn gate catches promised-but-undone work, buried findings, and unverified claims.
---

# Fable Turn Check

Before your final message, answer these four questions. A Stop hook
enforces #1 mechanically — the goal is to pass BEFORE it fires.

1. **Is my last paragraph a promise, plan, or permission request?**
   ("I'll…", "Next steps", "Let me know…", "Want me to…?") → Do that work
   now, with tool calls. Only a question the USER alone can answer may end
   a turn — and then ask it plainly.
2. **Did anything important appear only mid-turn or in my thinking?**
   (a finding, a failure, a decision) → Restate it in the final message.
3. **Am I claiming done/fixed/passing without having run it?** → Run the
   verification now. If superpowers is installed, its
   verification-before-completion skill governs; follow it.
4. **Is the claim big?** (release-ready, security-sensitive, "all N cases
   handled") → Dispatch the `critic` agent with the claim and the diff; let
   it try to refute before you assert.

Then apply fable-voice to the final message itself.
