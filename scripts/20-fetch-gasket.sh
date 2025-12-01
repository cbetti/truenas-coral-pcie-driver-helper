#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------
# 20-fetch-gasket.sh
#
# Fetch or update the Google gasket-driver source tree for building
# the Coral PCIe driver on TrueNAS SCALE.
#
# This script:
#   1. Ensures the artifacts directory exists:
#        ${ROOT_DIR}/artifacts
#   2. Uses or creates a checkout of:
#        https://github.com/google/gasket-driver
#      at:
#        ${ROOT_DIR}/artifacts/gasket-driver
#   3. If the repo already exists:
#        - `git fetch --all --prune`
#        - `git reset --hard` to a chosen ref:
#            * env GASKET_DRIVER_REF, if set
#            * otherwise origin/<remote-default-branch> (usually origin/main)
#      If the repo does not yet exist:
#        - `git clone` the repo
#        - optionally `git checkout` GASKET_DRIVER_REF if set.
#
# Environment variable:
#   GASKET_DRIVER_REF  (optional)
#     - If set, this script will:
#         * On first clone: `git checkout "${GASKET_DRIVER_REF}"`
#         * On update: `git reset --hard "${GASKET_DRIVER_REF}"`
#     - Good for pinning to a known-good tag or commit.
#
# To CLEAN UP / UNDO what this script does:
#
#   - Removing just the gasket-driver tree:
#       rm -rf "${ROOT_DIR}/artifacts/gasket-driver"
#
#   - Removing the entire Coral artifacts directory:
#       rm -rf "${ROOT_DIR}/artifacts"
#
#   - This script does NOT touch system-wide state; it only manages
#     files under your repo’s artifacts directory.
# ---------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="${ROOT_DIR}/artifacts"
GASKET_DIR="${ARTIFACT_DIR}/gasket-driver"

echo "==> [20-fetch-gasket] Repo root: ${ROOT_DIR}"
echo "==> Artifact dir: ${ARTIFACT_DIR}"
echo "==> Gasket dir: ${GASKET_DIR}"

mkdir -p "${ARTIFACT_DIR}"

if [ -d "${GASKET_DIR}/.git" ]; then
  echo "==> Existing gasket-driver repo found, updating"
  git -C "${GASKET_DIR}" fetch --all --prune

  if [ -n "${GASKET_DRIVER_REF:-}" ]; then
    # Caller explicitly requested a ref (tag/commit/branch)
    TARGET_REF="${GASKET_DRIVER_REF}"
  else
    # Discover the remote's default branch (HEAD) and build origin/<branch>
    REMOTE_HEAD_BRANCH="$(
      git -C "${GASKET_DIR}" remote show origin 2>/dev/null \
        | awk '/HEAD branch/ {print $NF}'
    )"

    if [ -z "${REMOTE_HEAD_BRANCH}" ]; then
      echo "WARN: Could not detect remote HEAD branch, trying origin/main then origin/master"
      if git -C "${GASKET_DIR}" rev-parse --verify origin/main >/dev/null 2>&1; then
        REMOTE_HEAD_BRANCH="main"
      elif git -C "${GASKET_DIR}" rev-parse --verify origin/master >/dev/null 2>&1; then
        REMOTE_HEAD_BRANCH="master"
      else
        echo "ERROR: No origin/main or origin/master found; cannot determine default ref."
        exit 1
      fi
    fi

    TARGET_REF="origin/${REMOTE_HEAD_BRANCH}"
  fi

  echo "==> Resetting gasket-driver to ${TARGET_REF}"
  git -C "${GASKET_DIR}" reset --hard "${TARGET_REF}"

else
  echo "==> Cloning gasket-driver from GitHub"
  git clone https://github.com/google/gasket-driver "${GASKET_DIR}"

  if [ -n "${GASKET_DRIVER_REF:-}" ]; then
    echo "==> Checking out requested ref ${GASKET_DRIVER_REF}"
    git -C "${GASKET_DIR}" checkout "${GASKET_DRIVER_REF}"
  fi
fi

echo "==> [20-fetch-gasket] Done."

