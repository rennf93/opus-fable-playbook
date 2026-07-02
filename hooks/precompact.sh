#!/usr/bin/env bash
# PreCompact: shape what survives compaction.
set -u
cat > /dev/null || true
cat <<'EOF'
Compaction guidance (fable-mode): the summary must preserve, outcome-first:
(1) current task state and remaining work, (2) what was verified, with the
actual results, (3) any failures not yet reported to the user, verbatim,
(4) pending user decisions, (5) paths of files being modified.
EOF
exit 0
