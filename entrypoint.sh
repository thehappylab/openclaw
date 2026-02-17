#!/bin/bash
set -e

OPENCLAW_USER="claw"
REAL_OPENCLAW_BIN="$(command -v openclaw || true)"

# ---------------------------------------------------------------------------
# Ensure /data is writable by the claw user (handles fresh volumes)
# ---------------------------------------------------------------------------
chown -R "$OPENCLAW_USER:$OPENCLAW_USER" /data 2>/dev/null || true

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
if [ "$(id -u)" = "0" ] && [ -n "$REAL_OPENCLAW_BIN" ]; then
  WRAPPER_DIR="/tmp/openclaw-wrapper"
  mkdir -p "$WRAPPER_DIR"
  cat > "$WRAPPER_DIR/openclaw" <<EOF
#!/bin/bash
if [ "\$(id -u)" = "0" ] && [ "\${1:-}" = "gateway" ]; then
  exec sudo -E -u "$OPENCLAW_USER" "$REAL_OPENCLAW_BIN" "\$@"
fi
exec "$REAL_OPENCLAW_BIN" "\$@"
EOF
  chmod +x "$WRAPPER_DIR/openclaw"
  export PATH="$WRAPPER_DIR:$PATH"
  echo "[entrypoint] openclaw gateway will run as user: $OPENCLAW_USER"
fi

exec /app/scripts/entrypoint.sh "$@"
