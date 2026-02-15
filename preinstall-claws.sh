#!/bin/bash
# ---------------------------------------------------------------------------
# Preinstalls OpenClaw skills from ClawHub if not already present.
# Runs in the background so it does not block gateway startup.
#
# Reads a comma-separated list of ClawHub slugs from the env var
# OPENCLAW_PREINSTALL_CLAWS (e.g. "steipete/summarize,steipete/github").
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

  # Derive folder name from the slug (owner/name -> name)
  skill_name="${claw##*/}"

  if [ -d "$SKILLS_DIR/$skill_name" ]; then
    echo "[preinstall-claws] Already installed: $claw"
    continue
  fi

  echo "[preinstall-claws] Installing: $claw"
  clawhub install "$claw" --workdir "$WORKDIR" --no-input 2>&1 || \
    echo "[preinstall-claws] Warning: Failed to install $claw (will retry on next restart)"
done

echo "[preinstall-claws] Done"
