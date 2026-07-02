---
description: Run the fable-mode eval suite (probes → pairwise judge → report). Costs tokens — runs headless claude many times. Optional arg: a probe id substring to filter.
---

Run the fable-mode convergence evals. `$ARGUMENTS` may contain a probe id
filter (e.g. `03`), and `--yes` to skip the cost confirmation.

1. Unless `--yes` was passed, tell the user how many probe runs this is
   (matched probes × 2 candidate modes + judging) and ask to proceed.
2. Ensure goldens exist in `evals/golden/` for the matched probes; for any
   missing, generate: `evals/run-probe.sh <probe> golden evals/golden`.
3. Run baseline + fable candidates into `evals/results/<today>/`, then judge
   each against its golden, per evals/LOOP.md steps 1–2 (respect the
   filter).
4. Run `evals/report.sh evals/results/<today>/` and present the table.
5. Interpret per LOOP.md step 4: name the weakest dimension and the exact
   doctrine section/hook/skill to strengthen. Do not apply changes —
   recommend them.
