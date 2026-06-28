#!/bin/bash
# VPS -> Mac bridge watcher.
# Watches the DEPLOYED app for new uploads (capture-page confirms -> cap-*.json,
# dashboard "Add item" -> review-*.json). When one appears it pulls ONLY the new
# photos down to the Mac and exits to wake Claude. Claude identifies the part,
# writes the result back to the VPS, then restarts this watcher.
#
# Speed notes:
#  - SSH ControlMaster keeps ONE connection warm across polls (no ~0.4s handshake
#    each tick; the rsync reuses it too).
#  - On detection we pull only the files find_unprocessed.py --png names, instead
#    of rsyncing the whole captures dir (which grows with the inventory).
#  - Only photos are pulled (never the VPS review/sidecar JSON) so the LOCAL
#    watcher isn't polluted by remote markers.
set -uo pipefail

ROOT="${INVENTORY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
: "${VPS_HOST:?set VPS_HOST (your server IP/hostname)}"
VPS="${VPS_USER:-root}@${VPS_HOST}"
VPSPATH="${VPS_PATH:-/opt/my-inventory}"
POLL="${BRIDGE_POLL:-2}"

CM="$HOME/.ssh/cm-inv-%r@%h:%p"
SSHOPTS=(-o BatchMode=yes -o ConnectTimeout=10 -o ControlMaster=auto -o "ControlPath=$CM" -o ControlPersist=120)
RSH="ssh -o BatchMode=yes -o ControlMaster=auto -o ControlPath=$CM -o ControlPersist=120"

# Warm the shared master connection once.
ssh "${SSHOPTS[@]}" "$VPS" true 2>/dev/null || true

while true; do
  hits=$(ssh "${SSHOPTS[@]}" "$VPS" "cd $VPSPATH && python3 deploy/find_unprocessed.py" 2>/dev/null || true)
  if [ -n "$hits" ]; then
    pngs=$(ssh "${SSHOPTS[@]}" "$VPS" "cd $VPSPATH && python3 deploy/find_unprocessed.py --png" 2>/dev/null || true)
    if [ -n "$pngs" ]; then
      printf '%s\n' "$pngs" | rsync -az -e "$RSH" --files-from=- \
        "$VPS:$VPSPATH/captures/" "$ROOT/captures/" 2>/dev/null || true
    else
      # fallback: whole-dir photo pull if --png unexpectedly returned nothing
      rsync -az -e "$RSH" --include='*.png' --exclude='*' \
        "$VPS:$VPSPATH/captures/" "$ROOT/captures/" 2>/dev/null || true
    fi
    echo "VPS UPLOAD(S) DETECTED:"
    echo "$hits"
    break
  fi
  sleep "$POLL"
done
