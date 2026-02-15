#!/bin/bash
set -e

# ---------------------------------------------------------------------------
# Configure Bitwarden CLI custom server (if BW_SERVER is set)
# ---------------------------------------------------------------------------
if [ -n "$BW_SERVER" ]; then
  echo "[entrypoint] Configuring Bitwarden CLI server: $BW_SERVER"
  bw config server "$BW_SERVER"
fi

# ---------------------------------------------------------------------------
# Hand off to the original openclaw entrypoint
# ---------------------------------------------------------------------------
exec /app/scripts/entrypoint.sh "$@"
