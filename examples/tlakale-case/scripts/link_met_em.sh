#!/bin/bash
# Link met_em files from WPS output into the WRF case directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

cd "${CASE_DIR}"
ln -sf "${WPS_CASE_DIR}"/met_em.d0*.nc .
echo "Linked met_em files into ${CASE_DIR}"
ls -la met_em.d0*.nc 2>/dev/null | head -5 || true
