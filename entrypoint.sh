#!/bin/bash
set -e

OPENCLAW_USER="claw"

# ---------------------------------------------------------------------------
# Ensure /data is writable by the runtime user (handles fresh volumes)
# ---------------------------------------------------------------------------
if [ "$(id -u)" = "0" ]; then
  chown -R "$OPENCLAW_USER:$OPENCLAW_USER" /data 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Install extra apt packages at runtime (if OPENCLAW_DOCKER_APT_PACKAGES set)
# ---------------------------------------------------------------------------
if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ] && [ "$(id -u)" = "0" ]; then
  echo "[entrypoint] Installing extra apt packages: $OPENCLAW_DOCKER_APT_PACKAGES"
  apt-get update -qq && apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES \
    && rm -rf /var/lib/apt/lists/*
fi

# ---------------------------------------------------------------------------
# Configure Bitwarden CLI custom server (if BW_SERVER is set)
# ---------------------------------------------------------------------------
if [ -n "$BW_SERVER" ]; then
  echo "[entrypoint] Configuring Bitwarden CLI server: $BW_SERVER"
  bw config server "$BW_SERVER"
fi

# ---------------------------------------------------------------------------
# Auto-configure Coolify CLI context (if COOLIFY_API_TOKEN is set)
# ---------------------------------------------------------------------------
if [ -n "${COOLIFY_API_TOKEN:-}" ]; then
  COOLIFY_URL="${COOLIFY_API_URL:-https://app.coolify.io}"
  echo "[entrypoint] Configuring Coolify CLI context (url: $COOLIFY_URL)"
  gosu "$OPENCLAW_USER" coolify context add default "$COOLIFY_URL" "$COOLIFY_API_TOKEN" --default --force 2>/dev/null || \
    echo "[entrypoint] Warning: Failed to configure Coolify CLI context"
fi

# ---------------------------------------------------------------------------
# Copy bundled skills into the workspace (non-destructive)
# ---------------------------------------------------------------------------
WORKDIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
SKILLS_DIR="$WORKDIR/skills"
if [ -d /bundled-skills ] && [ "$(ls -A /bundled-skills 2>/dev/null)" ]; then
  mkdir -p "$SKILLS_DIR"
  for skill in /bundled-skills/*/; do
    skill_name="$(basename "$skill")"
    if [ ! -d "$SKILLS_DIR/$skill_name" ]; then
      echo "[entrypoint] Installing bundled skill: $skill_name"
      cp -r "$skill" "$SKILLS_DIR/$skill_name"
      chown -R "$OPENCLAW_USER:$OPENCLAW_USER" "$SKILLS_DIR/$skill_name"
    fi
  done
fi

# ---------------------------------------------------------------------------
# Preinstall ClawHub skills in the background (non-blocking)
# ---------------------------------------------------------------------------
if [ -n "${OPENCLAW_PREINSTALL_CLAWS:-}" ]; then
  echo "[entrypoint] Preinstalling ClawHub skills in the background ..."
  gosu "$OPENCLAW_USER" /preinstall-claws.sh &
fi

# ---------------------------------------------------------------------------
# Drop privileges and hand off to the original openclaw entrypoint
# ---------------------------------------------------------------------------
if [ "$(id -u)" = "0" ]; then
  echo "[entrypoint] Dropping privileges to user: $OPENCLAW_USER"
  exec gosu "$OPENCLAW_USER" /app/scripts/entrypoint.sh "$@"
else
  exec /app/scripts/entrypoint.sh "$@"
fi
