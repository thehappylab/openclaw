#!/bin/bash
# ---------------------------------------------------------------------------
# Preinstalls OpenClaw skills from ClawHub if not already present.
# Runs in the background so it does not block gateway startup.
#
# Reads a comma-separated list of slugs from OPENCLAW_PREINSTALL_SKILLS.
# Skills are installed into $OPENCLAW_WORKSPACE_DIR/skills.
# ---------------------------------------------------------------------------
set -euo pipefail

SKILLS="${OPENCLAW_PREINSTALL_SKILLS:-}"
WORKDIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"

if [ -z "$SKILLS" ]; then
  exit 0
fi

IFS=',' read -ra SKILL_LIST <<< "$SKILLS"

SKILLS_DIR="$WORKDIR/skills"
mkdir -p "$SKILLS_DIR"

echo "[preinstall-claws] Checking ${#SKILL_LIST[@]} skill(s) in $SKILLS_DIR ..."

for slug in "${SKILL_LIST[@]}"; do
  slug=$(echo "$slug" | xargs)  # trim whitespace
  [ -z "$slug" ] && continue

  if [ -d "$SKILLS_DIR/$slug" ]; then
    echo "[preinstall-claws] Already installed: $slug"
    continue
  fi

  echo "[preinstall-claws] Installing: $slug"
  clawhub install "$slug" --workdir "$WORKDIR" --no-input 2>&1 || \
    echo "[preinstall-claws] Warning: Failed to install $slug (will retry on next restart)"
done

echo "[preinstall-claws] Done"
