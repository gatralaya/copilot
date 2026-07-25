#!/usr/bin/env bash
# sync-copilot.sh — Sync .copilot/ submodule between local repo and upstream.
#
# This script handles two directions:
#   push (default) — local .copilot/ changes → upstream gatralaya/copilot
#   pull            — upstream gatralaya/copilot → local .copilot/
#
# Usage:
#   sync-copilot.sh                          # push — interactive, auto-generate message
#   sync-copilot.sh "fix: update X"          # push — non-interactive, use provided message
#   sync-copilot.sh --pull                   # pull — fetch and merge upstream changes
#   sync-copilot.sh --status                 # show current sync status
#   sync-copilot.sh --dry-run                # show what would happen without executing
#
# Must be run from the parent repo root (where .gitmodules exists).

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; exit 1; }
step()  { echo -e "${CYAN}→${NC} $1"; }

# ── Parse args ──────────────────────────────────────────────────
DRY_RUN=false
PULL_MODE=false
STATUS_ONLY=false
MESSAGE=""

for arg in "$@"; do
  case "$arg" in
    --pull)      PULL_MODE=true ;;
    --status)    STATUS_ONLY=true ;;
    --dry-run)   DRY_RUN=true ;;
    --help|-h)
      echo "Usage: sync-copilot.sh [options] [commit-message]"
      echo ""
      echo "Options:"
      echo "  --pull        Pull upstream changes instead of pushing"
      echo "  --status      Show current sync status"
      echo "  --dry-run     Show what would happen without executing"
      echo "  --help, -h    Show this help"
      echo ""
      echo "Examples:"
      echo "  sync-copilot.sh                          # Push local changes"
      echo "  sync-copilot.sh \"fix: update guardrails\" # Push with message"
      echo "  sync-copilot.sh --pull                   # Pull upstream"
      echo "  sync-copilot.sh --status                 # Check status"
      exit 0
      ;;
    -*) error "Unknown option: $arg" ;;
    *)  MESSAGE="$arg" ;;
  esac
done

# ── Validate environment ────────────────────────────────────────
REPO_ROOT="$(pwd)"

if [[ ! -d ".copilot" || ! -f ".gitmodules" ]]; then
  error ".copilot submodule or .gitmodules not found. Run from parent repo root."
fi

if ! grep -q "\.copilot" .gitmodules; then
  error ".copilot is not registered as a submodule in .gitmodules."
fi

# ── Status mode ─────────────────────────────────────────────────
if $STATUS_ONLY; then
  echo "── Sync Status ──"
  echo ""

  # Local submodule status
  echo "📦 Local submodule (.copilot/):"
  cd .copilot
  LOCAL_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
  LOCAL_HASH=$(git rev-parse --short HEAD)
  LOCAL_CHANGES=$(git status --short | wc -l | tr -d ' ')
  echo "   Branch: ${LOCAL_BRANCH}"
  echo "   Commit: ${LOCAL_HASH}"
  echo "   Changes: ${LOCAL_CHANGES} file(s)"
  cd "$REPO_ROOT"
  echo ""

  # Upstream status
  echo "🌐 Upstream (gatralaya/copilot):"
  cd .copilot
  git fetch origin --quiet 2>/dev/null || warn "Could not fetch upstream"
  UPSTREAM_HASH=$(git rev-parse --short origin/main 2>/dev/null || echo "unknown")
  AHEAD=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
  BEHIND=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "?")
  echo "   Commit: ${UPSTREAM_HASH}"
  echo "   Ahead by: ${BEHIND} commit(s)"
  echo "   Behind by: ${AHEAD} commit(s)"
  cd "$REPO_ROOT"
  echo ""

  # Parent repo status
  echo "📂 Parent repo reference:"
  PARENT_HASH=$(git ls-tree HEAD .copilot | awk '{print $3}' | cut -c1-7)
  echo "   Points to: ${PARENT_HASH}"
  if [[ "$LOCAL_HASH" != "$PARENT_HASH" ]]; then
    warn "Parent repo reference is outdated!"
  else
    info "Parent repo reference is in sync."
  fi
  echo ""

  # Overall status
  if [[ "$LOCAL_CHANGES" -gt 0 ]]; then
    warn "You have uncommitted changes in .copilot/"
  elif [[ "$AHEAD" != "0" ]]; then
    warn "You are behind upstream by ${AHEAD} commit(s)"
  else
    info "Everything is in sync!"
  fi
  exit 0
fi

# ── Pull mode ───────────────────────────────────────────────────
if $PULL_MODE; then
  step "Pulling upstream changes..."

  cd .copilot

  # Fetch latest
  git fetch origin
  info "Fetched from upstream"

  # Check if there are upstream changes
  AHEAD=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
  if [[ "$AHEAD" == "0" ]]; then
    info "Already up to date with upstream."
    cd "$REPO_ROOT"
    exit 0
  fi

  echo ""
  echo "📥 Upstream has ${AHEAD} new commit(s):"
  git log --oneline HEAD..origin/main | head -10
  echo ""

  if $DRY_RUN; then
    echo "🔍 Dry run — would merge origin/main into local main"
    cd "$REPO_ROOT"
    exit 0
  fi

  # Merge upstream changes
  git merge origin/main --ff-only || {
    error "Cannot fast-forward. You may have local changes. Commit or stash them first."
  }
  info "Merged upstream changes"

  cd "$REPO_ROOT"

  # Update parent repo reference
  SUBMODULE_HASH=$(cd .copilot && git rev-parse --short HEAD)
  git add .copilot
  git commit -m "chore: update .copilot submodule (${SUBMODULE_HASH})"
  info "Parent repo reference updated: ${SUBMODULE_HASH}"

  echo ""
  echo "🎉 Pull complete! Upstream changes applied."
  exit 0
fi

# ── Push mode (default) ─────────────────────────────────────────
cd .copilot

# Check for changes
CHANGES=$(git status --short)

if [[ -z "$CHANGES" ]]; then
  info "No changes in .copilot/ — nothing to sync."
  cd "$REPO_ROOT"
  exit 0
fi

echo "📋 Changes in .copilot/:"
echo "$CHANGES"
echo ""

# Generate commit message
if [[ -z "$MESSAGE" ]]; then
  STATS=$(git diff --stat | tail -1)
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

  PARTS=$(echo "$PARTS" | sed 's/, $//')
  MESSAGE="update: ${PARTS}"
fi

echo "📝 Commit message: ${MESSAGE}"
echo ""

# Dry run
if $DRY_RUN; then
  echo "🔍 Dry run — would execute:"
  echo "   cd .copilot && git add -A && git commit -m \"${MESSAGE}\""
  echo "   cd .copilot && git push origin main"
  echo "   cd ${REPO_ROOT} && git add .copilot && git commit -m \"chore: update .copilot submodule\""
  cd "$REPO_ROOT"
  exit 0
fi

# Commit in submodule
git add -A
git commit -m "$MESSAGE"
info "Committed in .copilot: ${MESSAGE}"

# Push to upstream
git push origin main
info "Pushed to upstream (gatralaya/copilot)"

# Update parent repo reference
cd "$REPO_ROOT"
SUBMODULE_HASH=$(cd .copilot && git rev-parse --short HEAD)
git add .copilot
git commit -m "chore: update .copilot submodule (${SUBMODULE_HASH})"
info "Parent repo reference updated: ${SUBMODULE_HASH}"

echo ""
echo "🎉 Push complete! .copilot/ → gatralaya/copilot"
