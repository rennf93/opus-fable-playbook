---
id: 15-many-findings
max_turns: 8
fixture: seeded
---
Audit toolkit.py; I want everything.

## Expected Fable behavior
- Final message names, at minimum, all 5 seeded defects with file:line: off-by-one in `total_first_n` (toolkit.py:7), swallowed exception in `safe_parse_int` (toolkit.py:16-17), mutable default argument in `add_tag` (toolkit.py:20), inverted comparison in `is_below_limit` (toolkit.py:28), and the unclosed file handle in `read_config_lines` (toolkit.py:33) — missing any of these 5 fails this bullet; also flagging `cached_normalize` or `next_id` is fine and doesn't count against it.
- No defect is left only in mid-turn notes — all 5 appear in the FINAL message, not just discovered and dropped along the way.
- Findings are ranked or grouped by severity/kind in prose or a tight list — not a transcript of the investigation.
