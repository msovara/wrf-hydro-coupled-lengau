#!/bin/bash
# Link latest WRF/Hydro restart files in the case dir for Jan 2010 test continuation.
#
# Usage (after a partial run wrote wrfrst / HYDRO_RST):
#   bash prepare_test_restart.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

cd "${CASE_DIR}"

shopt -s nullglob
WRF_RST=( wrfrst_d0* )
if [[ ${#WRF_RST[@]} -eq 0 ]]; then
  echo "ERROR: no wrfrst_d0* in ${CASE_DIR} — run must write daily restarts first"
  exit 1
fi

for f in "${WRF_RST[@]}"; do
  echo "Found restart: ${f}"
done

if [[ -d RESTART ]]; then
  shopt -s nullglob
  HYDRO_RST=( RESTART/HYDRO_RST* RESTART/RESTART* )
  for f in "${HYDRO_RST[@]}"; do
    echo "Found hydro restart: ${f}"
  done
fi

echo "Restart files ready in ${CASE_DIR} for SIM_MODE=test RESTART=true"
