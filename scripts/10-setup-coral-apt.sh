#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------
# Coral APT repo setup for TrueNAS SCALE
#
# This script does the following:
#   1. Adds the Coral Edge TPU APT source to:
#        /etc/apt/sources.list.d/coral-edgetpu.list
#   2. Adds the Coral APT GPG key to:
#        /etc/apt/trusted.gpg.d/coral-edgetpu.gpg
#   3. Runs `apt-get update`.
#   4. Installs the libedgetpu userspace library:
#        libedgetpu1-std
#
# To CLEAN UP / UNDO these changes:
#
#   1) Remove the Coral APT source file:
#        rm -f /etc/apt/sources.list.d/coral-edgetpu.list
#
#   2) Remove the Coral APT keyring:
#        rm -f /etc/apt/trusted.gpg.d/coral-edgetpu.gpg
#
#   3) Uninstall libedgetpu1-std (optional, if no longer needed):
#        apt-get remove --purge -y libedgetpu1-std
#
#   4) Refresh APT metadata:
#        apt-get update -y
#
# After that, the system will be back to its pre-Coral-APT state
# (aside from any apt cache files that apt will manage itself).
# ---------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [10-setup-coral-apt] Repo root: ${ROOT_DIR}"

REPO_FILE="/etc/apt/sources.list.d/coral-edgetpu.list"
KEYRING="/etc/apt/trusted.gpg.d/coral-edgetpu.gpg"
REPO_LINE="deb https://packages.cloud.google.com/apt coral-edgetpu-stable main"

# Add APT source if needed
if [ -f "${REPO_FILE}" ]; then
  if grep -q "coral-edgetpu-stable" "${REPO_FILE}"; then
    echo "==> Coral APT repo already present in ${REPO_FILE}"
  else
    echo "==> Updating ${REPO_FILE} with Coral APT repo"
    echo "${REPO_LINE}" > "${REPO_FILE}"
  fi
else
  echo "==> Creating ${REPO_FILE} with Coral APT repo"
  echo "${REPO_LINE}" > "${REPO_FILE}"
fi

# Add key (via gpg --dearmor) if needed
if [ -f "${KEYRING}" ]; then
  echo "==> Coral APT keyring already present at ${KEYRING}"
else
  echo "==> Fetching Coral APT GPG key"
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o "${KEYRING}"
fi

echo "==> apt-get update (with Coral repo)"
apt-get update -y

# Install libedgetpu1-std if missing
if dpkg -s libedgetpu1-std >/dev/null 2>&1; then
  echo "==> libedgetpu1-std already installed"
else
  echo "==> Installing libedgetpu1-std"
  apt-get install -y libedgetpu1-std
fi

echo "==> [10-setup-coral-apt] Done."

