#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------
# Bootstrap build environment for Coral driver on TrueNAS SCALE
#
# This script does the following:
#
#   1. Calls `install-dev-tools`
#      - On TrueNAS SCALE, this:
#          * Enables the development toolchain / extra APT repos.
#          * Installs a baseline set of developer utilities.
#      - This is meant to be a one-way, system-wide change; there is
#        no simple, official "uninstall dev tools" path.
#
#   2. Runs:
#        apt-get update -y
#
#   3. Installs the following build/runtime dependencies (if missing):
#        git
#        dkms
#        devscripts
#        debhelper
#        dh-dkms
#        pciutils
#        curl
#        gnupg
#        lsb-release
#
# These are standard Debian build tools and utilities; they’re safe to
# leave installed and are likely useful for any future dev work.
#
# To *minimize* or partially undo the side effects:
#
#   - You generally should NOT try to undo `install-dev-tools`. It’s
#     designed by TrueNAS as a "turn on dev mode" operation, not a
#     toggle.
#
#   - If you really want to clean up the extra packages this script
#     explicitly installs, you can:
#
#       apt-get remove --purge -y \
#         git dkms devscripts debhelper dh-dkms pciutils curl gnupg lsb-release
#
#     followed by:
#
#       apt-get autoremove -y
#
#   - Doing so will remove the explicit build deps but will NOT fully
#     revert the system to a pre-dev-tools state.
#
# In normal use, the expectation is that you run this once to prepare
# the system for Coral driver builds and leave the environment in place.
# ---------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [00-bootstrap-env] Repo root: ${ROOT_DIR}"

if ! command -v install-dev-tools >/dev/null 2>&1; then
  echo "ERROR: install-dev-tools not found. Are you on TrueNAS SCALE with dev tools available?"
  exit 1
fi

echo "==> Running install-dev-tools (idempotent)"
install-dev-tools

echo "==> apt-get update"
apt-get update -y

DEPS=(
  git
  dkms
  devscripts
  debhelper
  dh-dkms
  pciutils
  curl
  gnupg
  lsb-release
)

echo "==> Installing build dependencies (if missing): ${DEPS[*]}"
apt-get install -y "${DEPS[@]}"

echo "==> [00-bootstrap-env] Done."

