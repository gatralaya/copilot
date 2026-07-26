#!/usr/bin/env bash
# clean-root.sh — Bersihkan semua file hasil init-core dan scaffold.
#
# Mengembalikan repo ke kondisi seperti habis clone:
# hanya .git/, .github/, .gitignore, README.md, .vscode/ yang tersisa.
#
# Usage:
#   .copilot/skills/clean-root/scripts/clean-root.sh
#
# Must be run from the repo root.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
STATE_FILE="${REPO_ROOT}/.core-state.json"

echo "── Cleaning root ──"
echo ""

# ── 1. Hapus file-file core dari state ──────────────────────────
# Files to NEVER delete (must survive clean)
SKIP_FILES=("Makefile")

if [[ -f "$STATE_FILE" ]]; then
  if command -v jq &>/dev/null; then
    jq -r '.files | keys[]' "$STATE_FILE" | while IFS= read -r file; do
      # Skip protected files
      skip=false
      for sf in "${SKIP_FILES[@]}"; do
        if [[ "$file" == "$sf" ]]; then skip=true; break; fi
      done
      if $skip; then
        echo "  ⊘ Skipped ${file} (protected)"
        continue
      fi
      target="${REPO_ROOT}/${file}"
      if [[ -f "$target" ]]; then
        rm -f "$target"
        echo "  ✓ Removed ${file}"
      fi
    done
  else
    PY_LIST=$(cat << 'PYEOF'
import json, sys
SKIP = {"Makefile"}
with open(sys.argv[1]) as f:
    state = json.load(f)
for k in sorted(state['files'].keys()):
    if k not in SKIP:
        print(k)
PYEOF
)
    while IFS= read -r file; do
      target="${REPO_ROOT}/${file}"
      if [[ -f "$target" ]]; then
        rm -f "$target"
        echo "  ✓ Removed ${file}"
      fi
    done < <(python3 -c "$PY_LIST" "$STATE_FILE")
  fi

  # Hapus .core-state.json setelah file-file dihapus
  rm -f "$STATE_FILE"
  echo "  ✓ Removed .core-state.json"
fi

# ── 3. Remove core/ and cmd/ folders (empty after removing files) ──
if [[ -d "${REPO_ROOT}/core" ]]; then
  rm -rf "${REPO_ROOT}/core"
  echo "  ✓ Removed core/"
fi
if [[ -d "${REPO_ROOT}/cmd" ]]; then
  rm -rf "${REPO_ROOT}/cmd"
  echo "  ✓ Removed cmd/"
fi

# ── 4. Hapus modules/ (semua scaffold) ──────────────────────────
if [[ -d "${REPO_ROOT}/modules" ]]; then
  rm -rf "${REPO_ROOT}/modules"
  echo "  ✓ Removed modules/"
fi

# ── 4b. Hapus components/ (shared components) ───────────────────
if [[ -d "${REPO_ROOT}/components" ]]; then
  rm -rf "${REPO_ROOT}/components"
  echo "  ✓ Removed components/"
fi

# ── 5. Hapus file root hasil init-core ──────────────────────────
for f in main.go go.mod go.sum package.json package-lock.json postcss.config.js vitest.config.ts vitest.setup.ts; do
  if [[ -f "${REPO_ROOT}/$f" ]]; then
    rm -f "${REPO_ROOT}/$f"
    echo "  ✓ Removed ${f}"
  fi
done

# ── 6. Hapus node_modules/ ──────────────────────────────────────
if [[ -d "${REPO_ROOT}/node_modules" ]]; then
  rm -rf "${REPO_ROOT}/node_modules"
  echo "  ✓ Removed node_modules/"
fi

# ── 7. Reset task queue & checkpoint ────────────────────────────
# Delegasikan ke reset-tasks.sh untuk DRY
RESET_SCRIPT="${REPO_ROOT}/.copilot/skills/reset-tasks/scripts/reset-tasks.sh"
if [[ -f "$RESET_SCRIPT" ]]; then
  bash "$RESET_SCRIPT" --quiet 2>/dev/null || true
  echo "  ✓ Reset .github/tasks/ (via reset-tasks.sh)"
fi

echo ""
echo "── Done ──"
echo "  Repository is clean. Run init-core.sh to start fresh."
echo "  .copilot/skills/init-core-project/scripts/init-core.sh"
