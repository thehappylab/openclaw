#!/bin/bash
set -e

OPENCLAW_USER="claw"
REAL_OPENCLAW_BIN="$(command -v openclaw || true)"
REAL_NODE_BIN="$(command -v node || true)"
STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"

# ---------------------------------------------------------------------------
# Ensure /data is writable by the claw user (handles fresh volumes)
# ---------------------------------------------------------------------------
chown -R "$OPENCLAW_USER:$OPENCLAW_USER" /data 2>/dev/null || true
mkdir -p "$STATE_DIR" 2>/dev/null || true
chown "$OPENCLAW_USER:$OPENCLAW_USER" "$STATE_DIR" 2>/dev/null || true
chmod 700 "$STATE_DIR" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Install extra apt packages at runtime (if OPENCLAW_DOCKER_APT_PACKAGES set)
# ---------------------------------------------------------------------------
if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then
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
  coolify context add default "$COOLIFY_URL" "$COOLIFY_API_TOKEN" --default --force 2>/dev/null || \
    echo "[entrypoint] Warning: Failed to configure Coolify CLI context"
fi

# ---------------------------------------------------------------------------
# Ensure gateway runs as non-root claw user
# (upstream entrypoint still needs root for nginx + runtime setup)
# ---------------------------------------------------------------------------
if [ "$(id -u)" = "0" ]; then
  WRAPPER_DIR="/tmp/openclaw-wrapper"
  mkdir -p "$WRAPPER_DIR"
  if [ -n "$REAL_OPENCLAW_BIN" ]; then
    cat > "$WRAPPER_DIR/openclaw" <<EOF
#!/bin/bash
STATE_DIR="\${OPENCLAW_STATE_DIR:-/data/.openclaw}"
OPENCLAW_JSON="\$STATE_DIR/openclaw.json"
if [ "\$(id -u)" = "0" ] && { [ "\${1:-}" = "gateway" ] || [ "\${1:-}" = "doctor" ]; }; then
  # Upstream setup runs as root and may leave state files root-owned.
  # Normalize ownership before commands that read/write ~/.openclaw state.
  if ! chown -R "$OPENCLAW_USER:$OPENCLAW_USER" /data; then
    echo "[entrypoint] WARNING: failed to chown /data recursively" >&2
  fi
  mkdir -p "\$STATE_DIR" 2>/dev/null || true
  if ! chown "$OPENCLAW_USER:$OPENCLAW_USER" "\$STATE_DIR" 2>/dev/null; then
    echo "[entrypoint] WARNING: failed to chown \$STATE_DIR" >&2
  fi
  chmod 700 "\$STATE_DIR" 2>/dev/null || true
  if [ -f "\$OPENCLAW_JSON" ]; then
    chown "$OPENCLAW_USER:$OPENCLAW_USER" "\$OPENCLAW_JSON" 2>/dev/null || true
    chmod 600 "\$OPENCLAW_JSON" 2>/dev/null || true
  fi
  exec sudo -E -u "$OPENCLAW_USER" "$REAL_OPENCLAW_BIN" "\$@"
fi
exec "$REAL_OPENCLAW_BIN" "\$@"
EOF
    chmod +x "$WRAPPER_DIR/openclaw"
  fi

  if [ -n "$REAL_NODE_BIN" ]; then
    cat > "$WRAPPER_DIR/node" <<EOF
#!/bin/bash
if [ "\$(id -u)" = "0" ] && [ "\${1:-}" = "/app/scripts/configure.js" ]; then
  # Ensure configure.js creates openclaw.json and .bak files as claw.
  OWNERSHIP_SCRIPT="\${OPENCLAW_DOCKER_OWNERSHIP_SCRIPT:-}"
  if [ -n "\$OWNERSHIP_SCRIPT" ]; then
    if [ -f "\$OWNERSHIP_SCRIPT" ] && [ -x "\$OWNERSHIP_SCRIPT" ]; then
      "\$OWNERSHIP_SCRIPT" || echo "[entrypoint] WARNING: ownership script failed: \$OWNERSHIP_SCRIPT" >&2
    else
      echo "[entrypoint] WARNING: OPENCLAW_DOCKER_OWNERSHIP_SCRIPT is not an executable file: \$OWNERSHIP_SCRIPT" >&2
    fi
  else
    chown -R "$OPENCLAW_USER:$OPENCLAW_USER" /data 2>/dev/null || true
  fi
  exec sudo -E -u "$OPENCLAW_USER" "$REAL_NODE_BIN" "\$@"
fi
exec "$REAL_NODE_BIN" "\$@"
EOF
    chmod +x "$WRAPPER_DIR/node"
  fi

  export PATH="$WRAPPER_DIR:$PATH"
  echo "[entrypoint] openclaw configure/doctor/gateway wrappers enabled for user: $OPENCLAW_USER"
fi

exec /app/scripts/entrypoint.sh "$@"
