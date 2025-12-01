#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------
# 40-install-gasket-deb.sh
#
# Install a previously built gasket-dkms_*.deb package onto the
# TrueNAS SCALE host using dpkg -i.
#
# This script:
#   1. Determines the current kernel via `uname -r`.
#   2. Chooses which .deb to install:
#        - If an explicit path is passed as $1, uses that.
#        - Otherwise tries:
#            ${ROOT_DIR}/artifacts/gasket-dkms_${KVER}.deb
#          where KVER is `uname -r`.
#        - If that does not exist, picks the latest:
#            ${ROOT_DIR}/artifacts/gasket-dkms_*.deb
#   3. Installs the chosen .deb with:
#        dpkg -i <deb-path>
#
# Notes:
#   - This affects system-wide kernel module state, since gasket-dkms
#     registers with DKMS. Upgrades to SCALE may require you to rebuild
#     and reinstall a new .deb for the new kernel.
#
# To CLEAN UP / UNDO the DKMS package:
#
#   - Uninstall the gasket-dkms package:
#       apt-get remove --purge -y gasket-dkms
#
#   - Remove any built .deb files (optional):
#       rm -f ${ROOT_DIR}/artifacts/gasket-dkms_*.deb
#
#   - If you want a full revert to no Coral kernel modules, combine
#     this with the cleanup steps for the APT repo/libedgetpu and
#     remove any /etc/modules-load.d or /etc/modprobe.d snippets you
#     have installed.
#
# Special TrueNAS sudo / DKMS note:
#   - If DKMS fails with messages like:
#       "sudo: argv[2] mismatch, expected ..."
#     then you likely need to disable TrueNAS's sudo intercept logging
#     in /etc/sudoers (via visudo) and start a fresh sudo session.
# ---------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="${ROOT_DIR}/artifacts"
KVER="$(uname -r)"

echo "==> [40-install-gasket-deb] Repo root: ${ROOT_DIR}"
echo "==> Kernel: ${KVER}"
echo "==> Artifact dir: ${ARTIFACT_DIR}"

# Optional first arg: explicit .deb path
if [ "${1:-}" != "" ]; then
  DEB_PATH="${1}"
  echo "==> Using explicit deb: ${DEB_PATH}"
else
  # First try kernel-specific name: gasket-dkms_<KVER>.deb
  CAND="${ARTIFACT_DIR}/gasket-dkms_${KVER}.deb"
  if [ -f "${CAND}" ]; then
    DEB_PATH="${CAND}"
    echo "==> Using kernel-specific deb: ${DEB_PATH}"
  else
    # Fallback: latest gasket-dkms_*.deb in artifacts
    echo "==> No kernel-specific deb found, picking latest gasket-dkms_*.deb in artifacts"
    DEB_PATH="$(ls -1 "${ARTIFACT_DIR}"/gasket-dkms_*.deb 2>/dev/null | sort | tail -n 1 || true)"
    if [ -z "${DEB_PATH}" ]; then
      echo "ERROR: No gasket-dkms_*.deb found in ${ARTIFACT_DIR}"
      exit 1
    fi
    echo "==> Selected: ${DEB_PATH}"
  fi
fi

# Sanity check: deb file must exist
if [ ! -f "${DEB_PATH}" ]; then
  echo "ERROR: Deb file ${DEB_PATH} does not exist."
  exit 1
fi

echo "==> Installing ${DEB_PATH} with dpkg -i"

# Wrap dpkg so we can print helpful guidance if DKMS/sudo intercept breaks
if ! dpkg -i "${DEB_PATH}"; then
  echo
  echo "ERROR: dpkg -i failed for ${DEB_PATH}."
  echo
  echo "On TrueNAS SCALE, this can happen when DKMS hits the sudo 'intercept'"
  echo "logging feature, which breaks long Kbuild command lines."
  echo
  echo "If you see messages like:"
  echo "    sudo: argv[2] mismatch, expected ..."
  echo
  echo "then do the following on the TrueNAS host:"
  echo "  1) Run:  visudo"
  echo "  2) Comment out these lines if present:"
  echo "       #Defaults log_subcmds"
  echo "       #Defaults log_format=json"
  echo "  3) Save and exit visudo."
  echo "  4) Exit your current sudo shell and start a new one, e.g.:"
  echo "       exit"
  echo "       sudo su"
  echo "  5) Re-run this script:"
  echo "       ${ROOT_DIR}/scripts/40-install-gasket-deb.sh"
  echo
  exit 1
fi

echo "==> [40-install-gasket-deb] Done."

