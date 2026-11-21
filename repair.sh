#!/usr/bin/env bash
# ==============================================================================
# Tukuk Server Repair & Self-Healing Agent
# Diagnoses and repairs backend services, systemd units, permissions, and hygiene.
# ==============================================================================
set -euo pipefail

echo "=== [Tukuk Repair] Starting Automated Server Diagnostics & Repair ==="

APP_DIR="/opt/tukuk-os"

# 1. Check and fix permissions
if [ -d "$APP_DIR" ]; then
  echo "[-] Fixing permissions on $APP_DIR ..."
  chown -R tukuk:tukuk "$APP_DIR" || true
  chmod -R 755 "$APP_DIR" || true
  chmod -R a+rwX "$APP_DIR/data" "$APP_DIR/content" "$APP_DIR/meili_data" 2>/dev/null || true
  echo "[+] Permissions fixed."
fi

# 2. Check and ensure MEILI_UPGRADE_DB in .env
if [ -f "$APP_DIR/.env" ]; then
  if ! grep -q "MEILI_UPGRADE_DB" "$APP_DIR/.env"; then
    echo "MEILI_UPGRADE_DB=true" >> "$APP_DIR/.env"
    echo "[+] Added MEILI_UPGRADE_DB=true to .env"
  fi
fi

# 3. Check Meilisearch service
if command -v systemctl >/dev/null 2>&1; then
  if systemctl list-unit-files | grep -q meilisearch; then
    if ! systemctl is-active --quiet meilisearch; then
      echo "[!] Meilisearch is inactive. Starting Meilisearch..."
      systemctl restart meilisearch || true
    else
      echo "[+] Meilisearch is active."
    fi
  fi

  # 4. Check Tukuk-OS service
  if systemctl list-unit-files | grep -q tukuk-os; then
    if ! systemctl is-active --quiet tukuk-os; then
      echo "[!] tukuk-os is inactive. Starting tukuk-os..."
      systemctl restart tukuk-os || true
    else
      echo "[+] tukuk-os is active."
    fi
  fi

  # 5. Check Cloudflared service
  if systemctl list-unit-files | grep -q cloudflared; then
    if ! systemctl is-active --quiet cloudflared; then
      echo "[!] cloudflared is inactive. Starting cloudflared..."
      systemctl restart cloudflared || true
    else
      echo "[+] cloudflared is active."
    fi
  fi
fi

# 6. Verify health
echo "[-] Verifying local health..."
if curl -sf -m 10 http://127.0.0.1:3000/ >/dev/null 2>&1; then
  echo "[+] Tukuk-OS is responding cleanly on port 3000."
else
  echo "[!] Warning: Port 3000 not answering yet. Check journalctl -u tukuk-os.service"
fi

echo "=== [Tukuk Repair] Repair sequence completed ==="
