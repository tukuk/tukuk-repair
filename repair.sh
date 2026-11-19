#!/usr/bin/env bash
# ==============================================================================
# Tukuk Server Repair & Self-Healing Agent
# Diagnoses and repairs backend services, PM2 processes, permissions, and hygiene.
# ==============================================================================
set -euo pipefail

echo "=== [Tukuk Repair] Starting Automated Server Diagnostics & Repair ==="

APP_DIR="/opt/tukuk-os"

# 1. Check and fix permissions
if [ -d "$APP_DIR" ]; then
  echo "[-] Fixing permissions on $APP_DIR ..."
  chown -R tukuk:tukuk "$APP_DIR" || true
  chmod -R 755 "$APP_DIR" || true
  chmod -R 775 "$APP_DIR/data" "$APP_DIR/content" 2>/dev/null || true
  echo "[+] Permissions fixed."
fi

# 2. Check Meilisearch service
if command -v systemctl >/dev/null 2>&1; then
  if systemctl list-unit-files | grep -q meilisearch; then
    if ! systemctl is-active --quiet meilisearch; then
      echo "[!] Meilisearch is inactive. Starting Meilisearch..."
      systemctl start meilisearch || true
    else
      echo "[+] Meilisearch is active."
    fi
  fi
fi

# 3. Check PM2 / Node backend (tukuk-os)
if command -v npx >/dev/null 2>&1 && [ -d "$APP_DIR" ]; then
  echo "[-] Checking PM2 processes..."
  cd "$APP_DIR"
  if npx pm2 status | grep -q "tukuk-os"; then
    echo "[+] tukuk-os is managed by PM2. Verifying health..."
    if ! curl -sf -m 5 "http://127.0.0.1:3000/health" >/dev/null; then
      echo "[!] /health endpoint failed or port 3000 busy. Restarting PM2 process..."
      npx pm2 restart tukuk-os || npx pm2 start index.js --name tukuk-os
    else
      echo "[+] tukuk-os /health responding successfully."
    fi
  else
    echo "[!] tukuk-os not found in PM2. Starting application..."
    PORT=3000 npx pm2 start index.js --name tukuk-os || true
    npx pm2 save || true
  fi
fi

# 4. Log and Temp hygiene
echo "[-] Cleaning stale logs and temp artifacts..."
find /tmp -name "tukuk-os-watchdog.*" -mmin +120 -delete 2>/dev/null || true
if command -v npx >/dev/null 2>&1; then
  npx pm2 flush 2>/dev/null || true
fi
echo "[+] Log and temp cleanup complete."

echo "=== [Tukuk Repair] Repair & Self-Healing Sequence Completed Successfully ==="
