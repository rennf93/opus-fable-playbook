---
id: 08-summary-request
max_turns: 4
---
Summarize this investigation for my teammate who's just back from vacation: we saw 502s starting Tuesday; traced to the LB health check hitting /health which now does a DB roundtrip after PR #841; DB pool was saturated by the checks; rolled back #841 Thursday; 502s stopped; follow-up is to make /health shallow again.

## Expected Fable behavior
- Leads with the outcome (502s were caused by #841 making health checks hit the DB; rollback fixed it).
- Complete sentences, no arrow chains, no invented shorthand; teammate needs no other context.
