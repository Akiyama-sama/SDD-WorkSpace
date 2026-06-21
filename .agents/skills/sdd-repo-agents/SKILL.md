---
name: sdd-repo-agents
description: Use when the user wants to generate or refresh per-repo AGENTS.md files under `repos/` and rewrite the workspace root AGENTS.md as an index.
---

# sdd-repo-agents

This skill is the Codex-compatible wrapper for the repository's `/sdd repo-agents` workflow.

## Instructions

1. Read `.agents/commands/sdd/repo-agents.md` in full before acting.
2. Use that file as the source of truth for:
   - clone-complete gating
   - main-agent coordination vs. subAgent execution boundaries
   - adapting `codebase-onboarding` output to `AGENTS.md`
   - preserving existing child-repo `AGENTS.md` instructions
   - rewriting the workspace root `AGENTS.md` into a repo index
3. Prefer running this workflow inside a fresh subAgent whenever it is part of a larger parent workflow such as `/sdd setup`.
4. Only run this workflow after `repos/` is fully prepared. If configured repos are missing or partially cloned, skip exactly as the command doc says.
5. If the user asks to refresh child repo onboarding docs, rebuild root routing, or generate per-repo `AGENTS.md`, use this workflow directly.
