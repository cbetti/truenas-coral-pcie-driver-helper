#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="$ROOT_DIR/artifacts"
KVER="$(uname -r)"

echo "==> Kernel: $KVER"

# 1. Bootstrap env
"$ROOT_DIR/scripts/00-bootstrap-env.sh"

# 2. Coral APT repo + libedgetpu
"$ROOT_DIR/scripts/10-setup-coral-apt.sh"

# 3. If we already have a gasket .deb built for this kernel, reuse it
DEB_PATTERN="$ARTIFACT_DIR/gasket-dkms_*_${KVER}.deb"
if ls $DEB_PATTERN >/dev/null 2>&1; then
  echo "==> Found prebuilt gasket for this kernel, installing"
  "$ROOT_DIR/scripts/40-install-gasket-deb.sh" "$DEB_PATTERN"
else
  echo "==> No gasket deb for this kernel, building fresh"
  "$ROOT_DIR/scripts/20-fetch-gasket.sh"
  "$ROOT_DIR/scripts/30-build-gasket-deb.sh"
  "$ROOT_DIR/scripts/40-install-gasket-deb.sh"
fi

# 4. Load modules
"$ROOT_DIR/scripts/50-load-modules.sh"

# 5. Status report
"$ROOT_DIR/scripts/60-report-status.sh"

# 6. Append notes entry
"$ROOT_DIR/scripts/70-write-notes-file.sh"

echo "==> Done."

