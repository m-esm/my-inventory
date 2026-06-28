#!/bin/bash
# Deploy code + current data to the VPS, then restart the service.
# Configure once (or pass on the command line):
#   export VPS_HOST=1.2.3.4        # your Hetzner VPS IP or hostname
#   export VPS_USER=root           # ssh user
#   export VPS_PATH=/opt/my-inventory
# Usage: ./deploy/deploy.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${VPS_HOST:?set VPS_HOST}"; : "${VPS_USER:=root}"; : "${VPS_PATH:=/opt/my-inventory}"

echo "Deploying $ROOT -> $VPS_USER@$VPS_HOST:$VPS_PATH"

# Sync everything EXCEPT secrets, local-only state, and bulky backups.
# NOTE: data/users.json is VPS-specific (created on the server) — never overwrite it.
rsync -az --delete \
  --exclude '.git' \
  --exclude '.remember' \
  --exclude '.claude' \
  --exclude 'data/users.json' \
  --exclude 'data/*.bak' \
  --exclude 'data/*.tmp' \
  "$ROOT/" "$VPS_USER@$VPS_HOST:$VPS_PATH/"

# Restart the service (assumes systemd unit already installed — see CLAUDE.md).
ssh "$VPS_USER@$VPS_HOST" "systemctl restart inventory && systemctl --no-pager status inventory | head -5"
echo "done."
