---
name: sync-copilot
description: Sync .copilot/ submodule between local repo and upstream gatralaya/copilot.
---

# Sync Copilot Skill

## When to use this

Use this skill when:
- **Updated shared config** — changed files in `.copilot/` (agents, instructions, prompts, skills, guardrails, architecture).
- **Fixed template headers** — added/updated template comments in `.copilot/tasks/` or `.copilot/specs/`.
- **Updated SKILL.md or scripts** — modified any skill definition or its scripts.
- **Want to push upstream** — after local edits to the submodule, sync back to `gatralaya/copilot`.
- **Want to pull upstream** — fetch and apply latest changes from `gatralaya/copilot`.

DO NOT use for:
- Changes to `.github/` (tasks, specs, workflows) — those are repo-specific, not shared.
- Changes to `.gitmodules` or submodule URL — use manual git commands.

## Quick Reference

| Command | Description |
|---|---|
| `make sync` | Push local changes to upstream |
| `make sync-pull` | Pull upstream changes |
| `make sync-status` | Show sync status |
| `sync-copilot.sh --help` | Show all options |

## How It Works

The script supports two directions:

### Push (Local → Upstream)

1. Enter `.copilot/` directory.
2. Check for any modified/added/deleted files.
3. If no changes, exit cleanly.
4. Auto-generate commit message from diff stats (or use provided message).
5. Stage and commit all changes.
6. Push to upstream `gatralaya/copilot`.
7. Return to parent repo and update the submodule reference.
8. Commit the reference update in the parent repo.

### Pull (Upstream → Local)

1. Fetch latest from upstream.
2. Check if there are new commits.
3. Fast-forward merge to latest.
4. Update parent repo reference.

## How to Run

### Via Makefile (Recommended)

```bash
make sync              # Push local changes
make sync-pull         # Pull upstream changes
make sync-status       # Check sync status
```

### Direct Script Usage

**Push mode (default):**

```bash
# Interactive — auto-generate commit message
.copilot/skills/sync-copilot/scripts/sync-copilot.sh

# Non-interactive — use provided message
.copilot/skills/sync-copilot/scripts/sync-copilot.sh "fix: update guardrails path"
```

**Pull mode:**

```bash
.copilot/skills/sync-copilot/scripts/sync-copilot.sh --pull
```

**Status check:**

```bash
.copilot/skills/sync-copilot/scripts/sync-copilot.sh --status
```

**Dry run (preview):**

```bash
.copilot/skills/sync-copilot/scripts/sync-copilot.sh --dry-run
```

## Status Output

The `--status` flag shows:

```
── Sync Status ──

📦 Local submodule (.copilot/):
   Branch: main
   Commit: 1e94221
   Changes: 0 file(s)

🌐 Upstream (gatralaya/copilot):
   Commit: 1e94221
   Ahead by: 0 commit(s)
   Behind by: 0 commit(s)

📂 Parent repo reference:
   Points to: 1e94221
   ✓ Parent repo reference is in sync.

✓ Everything is in sync!
```

## Output

On success (push):

```
✓ Committed in .copilot: <message>
✓ Pushed to upstream (gatralaya/copilot)
✓ Parent repo reference updated: <commit-hash>

🎉 Push complete! .copilot/ → gatralaya/copilot
```

On success (pull):

```
✓ Fetched from upstream
✓ Merged upstream changes
✓ Parent repo reference updated: <commit-hash>

🎉 Pull complete! Upstream changes applied.
```

## Notes

- This skill only works when the parent repo has a `.copilot` submodule configured.
- Requires push access to `github.com:gatralaya/copilot.git`.
- Pull mode uses `--ff-only` to prevent merge conflicts. Commit or stash local changes first if needed.
