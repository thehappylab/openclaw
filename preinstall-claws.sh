#!/bin/bash
# ---------------------------------------------------------------------------
# Preinstalls OpenClaw skills from ClawHub if not already present.
# Runs in the background so it does not block gateway startup.
#
# Reads a comma-separated list from the env var OPENCLAW_PREINSTALL_CLAWS.
# Entries can be "owner/name" (e.g. "steipete/summarize") or just "name".
# The CLI slug is always the name part only (owner/ prefix is stripped).
# Skills are installed into $OPENCLAW_WORKSPACE_DIR/skills.
# ---------------------------------------------------------------------------
set -euo pipefail

CLAWS="${OPENCLAW_PREINSTALL_CLAWS:-}"
WORKDIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"

if [ -z "$CLAWS" ]; then
  exit 0
fi

IFS=',' read -ra CLAW_LIST <<< "$CLAWS"

SKILLS_DIR="$WORKDIR/skills"
mkdir -p "$SKILLS_DIR"

echo "[preinstall-claws] Checking ${#CLAW_LIST[@]} skill(s) in $SKILLS_DIR ..."

for claw in "${CLAW_LIST[@]}"; do
  claw=$(echo "$claw" | xargs)  # trim whitespace
  [ -z "$claw" ] && continue

  # Strip owner prefix if present (steipete/summarize -> summarize)
  slug="${claw##*/}"

  if [ -d "$SKILLS_DIR/$slug" ]; then
    echo "[preinstall-claws] Already installed: $slug"
    continue
  fi

  echo "[preinstall-claws] Installing: $slug"
  clawhub install "$slug" --workdir "$WORKDIR" --no-input 2>&1 || \
    echo "[preinstall-claws] Warning: Failed to install $slug (will retry on next restart)"
done

echo "[preinstall-claws] Done"
