#!/usr/bin/env python3
"""Structural gate for the fable-mode plugin. Used by tests/run.sh and CI."""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ERRORS = []

# Later tasks append entries here (exact strings, repo-relative).
REQUIRED = [
    ".claude-plugin/plugin.json",
    "LICENSE",
    "README.md",
    "output-styles/fable.md",
    "hooks/lib/doctrine-card.md",
    "docs/claude-md-snippet.md",
    "profiles/opus-fable.settings.json",
    "hooks/lib/last_message.py",
    "tests/run.sh",
    "hooks/stop-gate.sh",
    "hooks/lib/telemetry.sh",
    "hooks/bash-discipline.sh",
    "hooks/honesty-nudge.sh",
    "hooks/session-start.sh",
    "hooks/prompt-nudge.sh",
    "hooks/precompact.sh",
    "hooks/hooks.json",
    "skills/fable-voice/SKILL.md",
    "skills/fable-fanout/SKILL.md",
    "skills/fable-turn-check/SKILL.md",
    "agents/critic.md",
    "commands/fable-status.md",
    ".github/workflows/ci.yml",
    "evals/rubric.md",
    "evals/run-probe.sh",
    "evals/judge.sh",
    "evals/report.sh",
    "evals/lib/isolation.py",
    ".claude-plugin/marketplace.json",
]


def err(msg):
    ERRORS.append(msg)


def p(rel):
    return os.path.join(ROOT, rel)


def frontmatter(rel):
    """Parse simple `key: value` frontmatter. Returns dict or None."""
    try:
        text = open(p(rel), encoding="utf-8").read()
    except OSError:
        return None
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    fm = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            fm[k.strip()] = v.strip()
    return fm


def word_count(rel):
    text = open(p(rel), encoding="utf-8").read()
    text = re.sub(r"^---\n.*?\n---\n", "", text, flags=re.S)
    return len(text.split())


def check_required():
    for rel in REQUIRED:
        if not os.path.exists(p(rel)):
            err(f"missing required file: {rel}")


def check_manifest():
    rel = ".claude-plugin/plugin.json"
    if not os.path.exists(p(rel)):
        return
    try:
        data = json.load(open(p(rel)))
    except (json.JSONDecodeError, OSError) as e:
        return err(f"{rel}: unparseable ({e})")
    for key in ("name", "version", "description"):
        if not data.get(key):
            err(f"{rel}: missing key {key}")
    if data.get("name") != "fable-mode":
        err(f"{rel}: name must be fable-mode")


def check_output_style():
    rel = "output-styles/fable.md"
    if not os.path.exists(p(rel)):
        return
    fm = frontmatter(rel)
    if fm is None:
        return err(f"{rel}: missing frontmatter")
    if fm.get("name") != "Fable":
        err(f"{rel}: frontmatter name must be Fable")
    if fm.get("keep-coding-instructions") != "true":
        err(f"{rel}: keep-coding-instructions must be true")
    wc = word_count(rel)
    if not 500 <= wc <= 1100:
        err(f"{rel}: body word count {wc} outside 500-1100")


def check_doctrine_card():
    rel = "hooks/lib/doctrine-card.md"
    if not os.path.exists(p(rel)):
        return
    wc = word_count(rel)
    if wc > 220:
        err(f"{rel}: doctrine card is {wc} words, max 220")


def check_hooks_json():
    rel = "hooks/hooks.json"
    if not os.path.exists(p(rel)):
        return
    try:
        data = json.load(open(p(rel)))
    except (json.JSONDecodeError, OSError) as e:
        return err(f"{rel}: unparseable ({e})")
    for event, groups in data.get("hooks", {}).items():
        for group in groups:
            for hook in group.get("hooks", []):
                cmd = hook.get("command", "")
                m = re.search(r"\$\{CLAUDE_PLUGIN_ROOT\}/(\S+?\.(?:sh|py))", cmd)
                if m and not os.path.exists(p(m.group(1))):
                    err(f"{rel}: {event} references missing {m.group(1)}")
                if m and not os.access(p(m.group(1)), os.X_OK):
                    err(f"{rel}: {m.group(1)} is not executable")


def check_skills_and_agents():
    for d in ("skills", "agents", "commands"):
        base = p(d)
        if not os.path.isdir(base):
            continue
        for dirpath, _, files in os.walk(base):
            for f in files:
                if not f.endswith(".md"):
                    continue
                rel = os.path.relpath(os.path.join(dirpath, f), ROOT)
                fm = frontmatter(rel)
                if fm is None:
                    err(f"{rel}: missing frontmatter")
                elif d == "skills" and not (fm.get("name") and fm.get("description")):
                    err(f"{rel}: skills need name + description")
                elif d != "skills" and not fm.get("description"):
                    err(f"{rel}: needs description")


def check_probes():
    base = p("evals/probes")
    if not os.path.isdir(base):
        return
    probes = [f for f in os.listdir(base) if f.endswith(".md")]
    if len(probes) != 12:
        err(f"evals/probes: expected 12 probes, found {len(probes)}")
    for f in sorted(probes):
        fm = frontmatter(os.path.join("evals/probes", f))
        if fm is None or not fm.get("id") or not fm.get("max_turns"):
            err(f"evals/probes/{f}: needs id + max_turns frontmatter")
            continue
        stem = os.path.splitext(f)[0]
        if fm.get("id") != stem:
            err(f"evals/probes/{f}: id {fm['id']!r} does not match filename stem {stem!r}")
        fixture = fm.get("fixture")
        if fixture and not os.path.isdir(p(os.path.join("evals/fixtures", fixture))):
            err(f"evals/probes/{f}: fixture {fixture!r} not found under evals/fixtures/")


def main():
    check_required()
    check_manifest()
    check_output_style()
    check_doctrine_card()
    check_hooks_json()
    check_skills_and_agents()
    check_probes()
    if ERRORS:
        for e in ERRORS:
            print(f"FAIL: {e}")
        return 1
    print("OK: structure check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
