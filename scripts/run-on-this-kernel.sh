#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KVER="$(uname -r)"

echo "==> Kernel: $KVER"

# 1. Bootstrap env
"$ROOT_DIR/scripts/00-bootstrap-env.sh"

# 2. Coral APT repo + libedgetpu
"$ROOT_DIR/scripts/10-setup-coral-apt.sh"

# 3. Always rebuild from the current upstream source and local compatibility
# patches. A kernel-named artifact may predate a newly added compatibility fix.
"$ROOT_DIR/scripts/20-fetch-gasket.sh"
"$ROOT_DIR/scripts/30-build-gasket-deb.sh"
"$ROOT_DIR/scripts/40-install-gasket-deb.sh"

# 4. Load modules
"$ROOT_DIR/scripts/50-load-modules.sh"

# 5. Status report
"$ROOT_DIR/scripts/60-report-status.sh"

# 6. Append notes entry
"$ROOT_DIR/scripts/70-write-notes-file.sh"

echo "==> Done."
