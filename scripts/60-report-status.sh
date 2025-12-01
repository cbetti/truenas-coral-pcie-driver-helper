#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------
# 60-report-status.sh
#
# Quick status report for the Coral PCIe driver on TrueNAS SCALE.
#
# Cleanup:
#   - Not needed. This script is read-only.
# ---------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [60-report-status] Repo root: ${ROOT_DIR}"
echo "==> Kernel: $(uname -r)"
echo

echo "==> Loaded modules (gasket/apex):"
if lsmod | grep -E '(^gasket|^apex)' >/dev/null 2>&1; then
  lsmod | grep -E '(^gasket|^apex)'
else
  echo "  (gasket/apex not currently loaded)"
fi
echo

echo "==> modinfo gasket (if available):"
if modinfo gasket >/dev/null 2>&1; then
  modinfo gasket | egrep '^(filename|version|srcversion|vermagic)'
else
  echo "  (modinfo gasket failed; module not installed?)"
fi
echo

echo "==> modinfo apex (if available):"
if modinfo apex >/dev/null 2>&1; then
  modinfo apex | egrep '^(filename|version|srcversion|vermagic)'
else
  echo "  (modinfo apex failed; module not installed?)"
fi
echo

echo "==> Coral PCI devices (lspci -nn | grep -i '1ac1\\|089a\\|coral'):"
if command -v lspci >/dev/null 2>&1; then
  if ! lspci -nn | grep -Ei '1ac1|089a|coral' >/dev/null 2>&1; then
    echo "  (no Coral devices found in lspci)"
  else
    lspci -nn | grep -Ei '1ac1|089a|coral'
  fi
else
  echo "  (lspci not found; install pciutils?)"
fi
echo

echo "==> /dev/apex* device nodes:"
if compgen -G "/dev/apex*" >/dev/null 2>&1; then
  ls -l /dev/apex*
else
  echo "  (no /dev/apex* devices present)"
fi

echo
echo "==> [60-report-status] Done."

