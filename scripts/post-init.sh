#!/usr/bin/env bash

LOGTAG="coral-post-init"

echo "$(date) [$LOGTAG] Starting Coral post-init"

# Try to load modules, ignore errors (they might already be loaded)
modprobe gasket 2>/dev/null || true
modprobe apex 2>/dev/null || true

if [ -e /dev/apex_0 ]; then
  echo "$(date) [$LOGTAG] Coral device /dev/apex_0 present"
else
  echo "$(date) [$LOGTAG] Coral device missing; check driver install"
fi

