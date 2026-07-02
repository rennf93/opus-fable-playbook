#!/usr/bin/env python3
"""Extract the last main-chain assistant text from a Claude Code transcript.

stdin: hook JSON containing transcript_path. stdout: text; empty on any
error (fail-open by contract).
"""
import json
import sys


def main():
    try:
        hook = json.load(sys.stdin)
        last = ""
        with open(hook.get("transcript_path", ""), encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if obj.get("type") != "assistant" or obj.get("isSidechain"):
                    continue
                content = (obj.get("message") or {}).get("content") or []
                texts = [b.get("text", "") for b in content
                         if isinstance(b, dict) and b.get("type") == "text"]
                if any(t.strip() for t in texts):
                    last = "\n".join(t for t in texts if t)
        sys.stdout.write(last)
    except Exception:
        pass


if __name__ == "__main__":
    main()
