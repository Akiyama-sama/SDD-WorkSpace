# SDD Workspace Guidance

This repository is a reusable SDD workspace template.

## Source Of Truth

- Treat `.agents/` as the canonical home for reusable workflow assets in this repo.
- Treat `.agents/commands/` as human-readable workflow specs for phase-based commands such as `/sdd start` and `/sdd close`.
- Treat `.agents/skills/` as the Codex-compatible execution surface for reusable workflows.
- Treat `.claude/` as a compatibility layer only. It mirrors `.agents/` through symlinks and should not become a second source of truth.

## Agent Compatibility

- Codex reads `AGENTS.md` for durable project guidance.
- Codex can discover repo skills from `.agents/skills`.
- Codex does not treat project-local `.agents/commands` as a native command registry. If the user mentions `/sdd` or `/opsx`, read the corresponding file under `.agents/commands/` and follow it.
- Claude-oriented tools may read `.claude/commands`, `.claude/skills`, and `.claude/mcp`. In this repo those paths point back to `.agents/`.

## Workflow Routing

- For lightweight requirement capture, use `.agents/commands/sdd/proposal.md`.
- For deeper requirement/design exploration, use `.agents/commands/sdd/brainstorming.md`.
- For spec generation and translation, use `.agents/commands/sdd/spec.md`.
- For implementation execution, use `.agents/commands/sdd/build.md`.
- For verification and archiving, use `.agents/commands/sdd/close.md`.

## Editing Rules

- When updating workflow behavior, modify `.agents/` first.
- If a compatibility symlink breaks, repair the symlink instead of copying files into `.claude/`.
- Keep guidance practical and short; move long procedures into command docs or skills.

## Verification

- After changing workflow docs, verify that `.agents/`, `.claude/`, `AGENTS.md`, and `CLAUDE.md` still point to the same behavior.
- Prefer adding repo skills over inventing Codex-only prompt files in `~/.codex/prompts` for shared workflows.
