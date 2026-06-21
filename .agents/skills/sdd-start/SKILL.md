---
name: sdd-start
description: Use when the user wants to start or resume the repository SDD workflow. Reads the repo's start-phase workflow spec and follows its routing, triage, and recovery rules.
---

# sdd-start

This skill is the Codex-compatible wrapper for the repository's `/sdd start` workflow.

## Instructions

1. Read `.agents/commands/sdd/start.md` in full before acting.
2. Treat that file as the source of truth for:
   - startup messaging
   - state detection
   - triage mode selection
   - phase routing
   - recovery behavior
3. If the user mentions `/sdd start`, "start the workflow", "resume the SDD flow", or equivalent, use that command doc directly.
4. Do not skip gating or routing steps described in the command doc.
