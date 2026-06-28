#!/bin/sh
# Ensure the admin account exists (from env), then run the server.
# ADMIN_USER / ADMIN_PASS come from deploy/admin.env (gitignored).
set -e

if [ -n "$ADMIN_USER" ] && [ -n "$ADMIN_PASS" ]; then
    python3 server.py adduser "$ADMIN_USER" "$ADMIN_PASS" admin >/dev/null 2>&1 || true
fi

exec python3 server.py
