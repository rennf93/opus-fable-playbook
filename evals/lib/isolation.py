#!/usr/bin/env python3
"""Emit a --settings JSON map that disables every user-enabled plugin.

Eval isolation can't use --bare (it drops OAuth/subscription auth — spec
amendment 2026-07-02), so runs pass this map via --settings instead.
Optional `--merge FILE` shallow-merges FILE's top-level keys over the map
so the fable profile rides along. Fail-safe: any error prints {} and
exits 0.
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
            out.update(json.load(open(sys.argv[2], encoding="utf-8")))
        print(json.dumps(out, separators=(",", ":")))
    except Exception:
        print("{}")


if __name__ == "__main__":
    main()
