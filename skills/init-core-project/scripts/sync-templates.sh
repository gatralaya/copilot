#!/usr/bin/env bash
# sync-templates.sh — Sync real core files ke template init-core-project.
#
# Setelah mengedit file di core/, root/, cmd/, atau modules/register.go,
# jalankan script ini agar template .tmpl juga ikut terupdate.
#
# Script ini otomatis mendeteksi file yang perlu di-sync dari .core-state.json,
# jadi tidak perlu hardcode daftar file secara manual.
#
# Usage:
#   .github/skills/init-core-project/scripts/sync-templates.sh
#
# Must be run from the repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATES_DIR="${SKILL_DIR}/templates"
STATE_FILE="${SKILL_DIR}/../../.core-state.json"

echo "── Syncing core files to templates ──"
echo ""

# Baca daftar file dari .core-state.json (otomatis — tidak perlu hardcode)
if [[ ! -f "$STATE_FILE" ]]; then
  echo "  ⚠️  .core-state.json not found. Run init-core.sh first."
  exit 1
fi

if command -v jq &>/dev/null; then
  FILES=$(jq -r '.files | keys[]' "$STATE_FILE")
else
  FILES=$(python3 -c "
import json, sys
with open('$STATE_FILE') as f:
    state = json.load(f)
for k in sorted(state['files'].keys()):
    print(k)
  " 2>/dev/null || true)
fi

SYNCED=0
SKIPPED=0

while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  target="${TEMPLATES_DIR}/${rel}.tmpl"
  mkdir -p "$(dirname "$target")"

  if [[ -f "$rel" ]]; then
    cp "$rel" "$target"
    echo "  ✓  ${rel} → .tmpl"
    SYNCED=$((SYNCED + 1))
  else
    echo "  ⚠️  ${rel} not found, skipping"
    SKIPPED=$((SKIPPED + 1))
  fi
done <<< "$FILES"

echo ""
echo "── Done (synced: ${SYNCED}, skipped: ${SKIPPED}) ──"