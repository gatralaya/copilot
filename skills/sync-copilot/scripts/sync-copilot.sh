#!/usr/bin/env bash
# sync-copilot.sh — Sync .copilot/ submodule changes to upstream gatralaya/copilot.
#
# This script:
#   1. Checks for changes in .copilot/
#   2. Commits with a provided or auto-generated message
#   3. Pushes to upstream (gatralaya/copilot)
#   4. Updates the submodule reference in the parent repo
#
# Usage:
#   sync-copilot.sh                    # interactive — auto-generate message, confirm
#   sync-copilot.sh "fix: update X"    # non-interactive — use provided message
#
# Options:
#   <message>   Commit message (optional, auto-generated if omitted)
#   --dry-run   Show what would happen without executing
#   --help      Show usage
#
# Must be run from the parent repo root (where .gitmodules exists).

set -euo pipefail

# ── Parse args ──────────────────────────────────────────────────
DRY_RUN=false
MESSAGE=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h) echo "Usage: sync-copilot.sh [--dry-run] [commit-message]"; exit 0 ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) MESSAGE="$arg" ;;
  esac
done

# ── Validate environment ────────────────────────────────────────
REPO_ROOT="$(pwd)"

if [[ ! -d ".copilot" || ! -f ".gitmodules" ]]; then
  echo "❌ Error: .copilot submodule or .gitmodules not found."
  echo "   Run this script from the parent repo root."
  exit 1
fi

if ! grep -q "\.copilot" .gitmodules; then
  echo "❌ Error: .copilot is not registered as a submodule in .gitmodules."
  exit 1
fi

cd .copilot

# ── Check for changes ───────────────────────────────────────────
CHANGES=$(git status --short)

if [[ -z "$CHANGES" ]]; then
  echo "✓ No changes in .copilot/ — nothing to sync."
  exit 0
fi

echo "📋 Changes in .copilot/:"
echo "$CHANGES"
echo ""

# ── Generate commit message ─────────────────────────────────────
if [[ -z "$MESSAGE" ]]; then
  # Auto-generate from diff stats
  STATS=$(git diff --stat | tail -1)
  # Extract file type counts
  SKILL_COUNT=$(echo "$CHANGES" | grep -c "skills/" || true)
  AGENT_COUNT=$(echo "$CHANGES" | grep -c "agents/" || true)
  INSTR_COUNT=$(echo "$CHANGES" | grep -c "instructions/" || true)
  PROMPT_COUNT=$(echo "$CHANGES" | grep -c "prompts/" || true)
  OTHER_COUNT=$(echo "$CHANGES" | grep -cv "skills/\|agents/\|instructions/\|prompts/" || true)

  PARTS=""
  [[ "$SKILL_COUNT" -gt 0 ]] && PARTS="${PARTS}${SKILL_COUNT} skills, "
  [[ "$AGENT_COUNT" -gt 0 ]] && PARTS="${PARTS}${AGENT_COUNT} agents, "
  [[ "$INSTR_COUNT" -gt 0 ]] && PARTS="${PARTS}${INSTR_COUNT} instructions, "
  [[ "$PROMPT_COUNT" -gt 0 ]] && PARTS="${PARTS}${PROMPT_COUNT} prompts, "
  [[ "$OTHER_COUNT" -gt 0 ]] && PARTS="${PARTS}${OTHER_COUNT} other"

  # Clean up trailing ", "
  PARTS=$(echo "$PARTS" | sed 's/, $//')

  MESSAGE="update: ${PARTS} — ${STATS}"
fi

echo "📝 Commit message: ${MESSAGE}"
echo ""

# ── Dry run ─────────────────────────────────────────────────────
if $DRY_RUN; then
  echo "🔍 Dry run — would execute:"
  echo "   git add -A && git commit -m \"${MESSAGE}\""
  echo "   git push origin main"
  echo "   cd ${REPO_ROOT} && git add .copilot && git commit -m \"chore: update .copilot submodule\""
  exit 0
fi

# ── Commit in submodule ─────────────────────────────────────────
git add -A
git commit -m "$MESSAGE"
echo "✓ Committed in .copilot: ${MESSAGE}"

# ── Push to upstream ────────────────────────────────────────────
git push origin main
echo "✓ Pushed to upstream (gatralaya/copilot)"

# ── Update parent repo reference ────────────────────────────────
cd "$REPO_ROOT"
SUBMODULE_HASH=$(cd .copilot && git rev-parse --short HEAD)
git add .copilot
git commit -m "chore: update .copilot submodule (${SUBMODULE_HASH})"
echo "✓ Parent repo reference updated: ${SUBMODULE_HASH}"

echo ""
echo "🎉 Sync complete! .copilot/ → gatralaya/copilot"
