#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------
# 50-load-modules.sh
#
# Load the Coral PCIe kernel modules (gasket + apex) and verify that
# /dev/apex* devices exist.
#
# This script:
#   1. Runs:
#        modprobe gasket
#        modprobe apex
#      ignoring errors (e.g., already loaded).
#   2. Checks for device nodes:
#        /dev/apex*
#      and prints them if found.
#   3. Returns:
#        exit 0 if /dev/apex* exists
#        exit 1 if no /dev/apex* was found
#
# Typical usage:
#   - After installing gasket-dkms, run this to confirm that the
#     modules load and Coral devices appear.
#   - This can also be called from your post-init script.
#
# To CLEAN UP / REVERT the in-memory state:
#
#   - Unload the modules (if nothing is using them):
#       modprobe -r apex
#       modprobe -r gasket
#
#   - This does NOT remove the DKMS package or any APT repos; it only
#     affects the current running kernel session.
# ---------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [50-load-modules] Repo root: ${ROOT_DIR}"

echo "==> modprobe gasket (ignore error if already loaded)"
if ! modprobe gasket 2>/dev/null; then
  echo "WARN: modprobe gasket failed (it may already be loaded or missing)."
fi

echo "==> modprobe apex (ignore error if already loaded)"
if ! modprobe apex 2>/dev/null; then
  echo "WARN: modprobe apex failed (it may already be loaded or missing)."
fi

# Check for /dev/apex* devices
if compgen -G "/dev/apex*" >/dev/null 2>&1; then
  echo "==> /dev/apex* device nodes:"
  ls -l /dev/apex*
  echo "==> [50-load-modules] Success: Coral devices present."
  exit 0
else
  echo "ERROR: No /dev/apex* devices found after loading modules."
  exit 1
fi

