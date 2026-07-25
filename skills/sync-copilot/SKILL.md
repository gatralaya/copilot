---
name: sync-copilot
description: Sync changes in .copilot/ submodule back to the upstream gatralaya/copilot repo.
---

# Sync Copilot Skill

## When to use this

Use this skill when:
- **Updated shared config** — changed files in `.copilot/` (agents, instructions, prompts, skills, guardrails, architecture).
- **Fixed template headers** — added/updated template comments in `.copilot/tasks/` or `.copilot/specs/`.
- **Updated SKILL.md or scripts** — modified any skill definition or its scripts.
- **Want to push upstream** — after local edits to the submodule, sync back to `gatralaya/copilot`.

DO NOT use for:
- Changes to `.github/` (tasks, specs, workflows) — those are repo-specific, not shared.
- Changes to `.gitmodules` or submodule URL — use manual git commands.

## How It Works

The `sync-copilot.sh` script will:

1. Enter `.copilot/` directory.
2. Check for any modified/added/deleted files.
3. If no changes, exit cleanly.
4. Prompt for a commit message (or auto-generate one from git diff stats).
5. Stage and commit all changes.
6. Push to upstream `gatralaya/copilot`.
7. Return to parent repo and update the submodule reference.
8. Commit the reference update in the parent repo.

## How to Run

### Agent Flow (Recommended)

The agent should check for changes first via `run_in_terminal`, then run the skill script.

**Step 1 — Check for changes:**

```bash
cd .copilot && git status --short
```

If empty, inform user: "No changes in `.copilot/` — nothing to sync."

**Step 2 — Run the sync script:**

```bash
.copilot/skills/sync-copilot/scripts/sync-copilot.sh
```

Or with a custom commit message:

```bash
.copilot/skills/sync-copilot/scripts/sync-copilot.sh "fix: update guardrails path reference"
```

### Interactive Mode (No arguments)

```bash
.copilot/skills/sync-copilot/scripts/sync-copilot.sh
```

The script will:
1. Auto-generate a commit message from diff stats (e.g., `"update: 5 files changed (2 skills, 1 agent, 2 templates)"`)
2. Show the proposed message
3. Ask for confirmation

### Non-Interactive Mode (With message)

```bash
.copilot/skills/sync-copilot/scripts/sync-copilot.sh "refactor: path cleanup for submodule"
```

Skips confirmation — commits and pushes immediately.

## Output

On success, the script prints:

```
✓ Committed in .copilot: <message>
✓ Pushed to upstream (gatralaya/copilot)
✓ Parent repo reference updated: <commit-hash>
```

On failure, it exits with a clear error message.

## Notes

- This skill only works when the parent repo has a `.copilot` submodule configured.
- Requires push access to `github.com:gatralaya/copilot.git`.
- The parent repo commit message will be auto-generated: `chore: update .copilot submodule (<short summary>)`.
