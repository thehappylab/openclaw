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
# Drop privileges and hand off to the original openclaw entrypoint
# ---------------------------------------------------------------------------
if [ "$(id -u)" = "0" ]; then
  echo "[entrypoint] Dropping privileges to user: $OPENCLAW_USER"
  exec gosu "$OPENCLAW_USER" /app/scripts/entrypoint.sh "$@"
else
  exec /app/scripts/entrypoint.sh "$@"
fi
