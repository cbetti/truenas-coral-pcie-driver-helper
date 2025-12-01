#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------
# 70-write-notes-file.sh
#
# Append a "lab notebook" entry for the current kernel to:
#
#   ${ROOT_DIR}/notes/kernel-<uname -r>.md
# ---------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="${ROOT_DIR}/artifacts"
NOTES_DIR="${ROOT_DIR}/notes"
KVER="$(uname -r)"

mkdir -p "${NOTES_DIR}"

NOTES_FILE="${NOTES_DIR}/kernel-${KVER}.md"

TRUENAS_VER="$(cat /etc/version 2>/dev/null || echo 'unknown')"
GASKET_VER="$(modinfo -F version gasket 2>/dev/null || echo 'n/a')"
APEX_VER="$(modinfo -F version apex 2>/dev/null || echo 'n/a')"

GASKET_COMMIT="$(
  cd "${ARTIFACT_DIR}/gasket-driver" 2>/dev/null && git rev-parse HEAD 2>/dev/null || echo 'n/a'
)"

{
  echo "## $(date --iso-8601=seconds)"
  echo
  echo "- TrueNAS version: ${TRUENAS_VER}"
  echo "- Kernel: ${KVER}"
  echo "- gasket-dkms .deb: ${ARTIFACT_DIR}/gasket-dkms_${KVER}.deb"
  echo "- gasket version: ${GASKET_VER}"
  echo "- apex version: ${APEX_VER}"
  echo "- gasket-driver commit: ${GASKET_COMMIT}"
  echo "- patches: gasket-no_llseek-truenas-6.12 (applied by 30-build-gasket-deb.sh)"
  echo "- dh_md5sums override: present in debian/rules"
  echo
} >> "${NOTES_FILE}"

echo "==> [70-write-notes-file] Appended notes entry to ${NOTES_FILE}"

