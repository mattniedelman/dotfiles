#!/usr/bin/env bash
# SessionStart hook: inject proactive skill usage instructions

cat <<'EOF'
# Proactive Skill Usage

**Before responding to ANY user message, check if a skill might apply.**

If there is even a 1% chance a skill applies, invoke it with the Skill tool BEFORE doing anything else — including clarifying questions, exploring code, or gathering context.

Red flags that mean STOP and check for skills:
- "This is just a simple question" — Questions are tasks. Check for skills.
- "I need more context first" — Skill check comes BEFORE clarifying questions.
- "Let me explore the codebase first" — Skills tell you HOW to explore. Check first.
- "This doesn't need a formal skill" — If a skill exists, use it.
- "The skill is overkill" — Simple things become complex. Use it.
- "I'll just do this one thing first" — Check BEFORE doing anything.

Skill priority: process skills first (brainstorming, debugging), then implementation skills.
EOF
