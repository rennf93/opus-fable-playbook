#!/usr/bin/env bash
# SessionStart: inject the doctrine card; flag inactive output style.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
cat > /dev/null || true   # drain stdin

CARD="$DIR/lib/doctrine-card.md"
[ -f "$CARD" ] && cat "$CARD"

STYLE="$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.claude/settings.json'))).get('outputStyle',''))" 2>/dev/null || true)"
if [ "$STYLE" != "Fable" ]; then
  printf '\nNote: the Fable output style is not set in user settings. If this session should run fable-mode fully, suggest the user run /output-style fable (or set "outputStyle": "Fable" in settings).\n'
fi
exit 0
