#!/bin/bash
# Archive end-of-year WRF/Hydro restart files for Phase 1 year chaining.
#
# Usage:  RUN_YEAR=1980 bash archive_year_restart.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

RUN_YEAR="${RUN_YEAR:?Set RUN_YEAR}"
DEST="${RESTART_ARCHIVE}/${RUN_YEAR}"

mkdir -p "${DEST}"
cd "${CASE_DIR}"

shopt -s nullglob
for f in wrfrst_d0*; do
  cp -a "${f}" "${DEST}/"
  echo "Archived ${f} -> ${DEST}/"
done

if [[ -d RESTART ]]; then
  cp -a RESTART/* "${DEST}/" 2>/dev/null || true
fi

echo "Year ${RUN_YEAR} restarts archived under ${DEST}"
