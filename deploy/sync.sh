#!/bin/bash
# Two-way MERGE sync between the Mac and the VPS (safe — never overwrites/loses
# items). Unions inventory + pending by id, copies photos both directions, and
# writes the merged result to both sides. Use this instead of the old one-way
# sync-data.sh now that items can be born on either side (Mac capture OR the
# deployed app).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${VPS_HOST:?set VPS_HOST (your server IP/hostname)}"
VPS="${VPS_USER:-root}@${VPS_HOST}"
VPSPATH="${VPS_PATH:-/opt/my-inventory}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Pulling VPS state…"
ssh -o BatchMode=yes "$VPS" "cat $VPSPATH/data/inventory.json" > "$TMP/vps-inv.json"
ssh -o BatchMode=yes "$VPS" "cat $VPSPATH/data/pending.json"   > "$TMP/vps-pending.json" 2>/dev/null || echo '{"pending":[]}' > "$TMP/vps-pending.json"

echo "Merging (union by id; prefer the more-complete entry)…"
python3 - "$ROOT" "$TMP" <<'PY'
import json, sys, os
root, tmp = sys.argv[1], sys.argv[2]

def load(p, default):
    try:
        with open(p) as f: return json.load(f)
    except Exception: return default

mac = load(os.path.join(root, "data/inventory.json"), {"items": []})
vps = load(os.path.join(tmp, "vps-inv.json"), {"items": []})

def score(it):
    return (1 if (it.get("name") or "").strip() else 0,
            len(it.get("images") or []),
            len(it.get("notes") or ""))

merged = {}
for it in mac.get("items", []) + vps.get("items", []):
    i = it.get("id")
    if not i:  # safety: skip id-less rows rather than risk dropping a real one
        continue
    if i not in merged or score(it) > score(merged[i]):
        merged[i] = it
out = {"items": list(merged.values())}

# pending: union by pending_id
macp = load(os.path.join(root, "data/pending.json"), {"pending": []})
vpsp = load(os.path.join(tmp, "vps-pending.json"), {"pending": []})
pm = {}
for p in macp.get("pending", []) + vpsp.get("pending", []):
    if p.get("pending_id"): pm[p["pending_id"]] = p
outp = {"pending": list(pm.values())}

with open(os.path.join(tmp, "merged-inv.json"), "w") as f: json.dump(out, f, indent=2)
with open(os.path.join(tmp, "merged-pending.json"), "w") as f: json.dump(outp, f, indent=2)
print("  merged items: %d (mac had %d, vps had %d)" % (len(out["items"]), len(mac.get("items", [])), len(vps.get("items", []))))
PY

echo "Writing merged inventory to both sides…"
cp "$TMP/merged-inv.json" "$ROOT/data/inventory.json"
cp "$TMP/merged-pending.json" "$ROOT/data/pending.json"
rsync -az "$TMP/merged-inv.json"     "$VPS:$VPSPATH/data/inventory.json"
rsync -az "$TMP/merged-pending.json" "$VPS:$VPSPATH/data/pending.json"

echo "Syncing photos both ways (no deletes, no review markers)…"
rsync -az --include='*.png' --exclude='*' "$VPS:$VPSPATH/captures/" "$ROOT/captures/"
rsync -az --include='*.png' --exclude='*' "$ROOT/captures/" "$VPS:$VPSPATH/captures/"

echo "Merge sync complete."
