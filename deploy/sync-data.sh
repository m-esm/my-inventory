#!/bin/bash
# Push ONLY the inventory data + photos to the VPS (for after a capture session
# on the Mac). Does not touch server code or the VPS's users.json.
# Captures happen on the Mac (iPhone camera), so the Mac stays the source of
# truth and the VPS is the shared viewing mirror.
#   export VPS_HOST=1.2.3.4 VPS_USER=root VPS_PATH=/opt/my-inventory
# Usage: ./deploy/sync-data.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${VPS_HOST:?set VPS_HOST}"; : "${VPS_USER:=root}"; : "${VPS_PATH:=/opt/my-inventory}"

# inventory.json + pending.json + all photos. Exclude secrets and .bak files.
rsync -az \
  --exclude '*.bak' --exclude '*.tmp' --exclude 'users.json' \
  "$ROOT/data/" "$VPS_USER@$VPS_HOST:$VPS_PATH/data/"
rsync -az "$ROOT/captures/" "$VPS_USER@$VPS_HOST:$VPS_PATH/captures/"
echo "data + photos synced to $VPS_HOST"
