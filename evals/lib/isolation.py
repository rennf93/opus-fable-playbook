#!/usr/bin/env python3
"""Emit a --settings JSON map that disables every user-enabled plugin.

Eval isolation can't use --bare (it drops OAuth/subscription auth — spec
amendment 2026-07-02), so runs pass this map via --settings instead.
Optional `--merge FILE` shallow-merges FILE's top-level keys over the map
so the fable profile rides along. Fail-safe: errors never exit nonzero —
a broken merge file keeps the disable map; only a total failure prints {}.
"""
import json
import os
import sys


def main():
    try:
        try:
            user = json.load(open(os.path.expanduser("~/.claude/settings.json"),
                                  encoding="utf-8"))
        except (OSError, ValueError):
            user = {}
        plugins = user.get("enabledPlugins")
        if not isinstance(plugins, dict):
            plugins = {}
        out = {"enabledPlugins": {k: False for k in plugins}}
        if len(sys.argv) >= 3 and sys.argv[1] == "--merge":
            try:
                extra = json.load(open(sys.argv[2], encoding="utf-8"))
            except (OSError, ValueError):
                extra = {}
            if not isinstance(extra, dict):
                extra = {}
            # Shallow merge: top-level keys from the merge file win. A merge
            # file carrying its own "enabledPlugins" would REPLACE the disable
            # map — no current profile has one; revisit if that ever changes.
            out.update(extra)
        print(json.dumps(out, separators=(",", ":")))
    except Exception:
        print("{}")


if __name__ == "__main__":
    main()
