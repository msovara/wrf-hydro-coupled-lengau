#!/bin/bash
# Link WRF (and optionally hydro) restart files from the previous year for Phase 1 chaining.
#
# Usage:
#   PREV_YEAR=1979 RUN_YEAR=1980 bash prepare_year_restart.sh
#   (PREV_YEAR archive must exist under RESTART_ARCHIVE)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

PREV_YEAR="${PREV_YEAR:?Set PREV_YEAR (e.g. 1979 when starting 1980)}"
RUN_YEAR="${RUN_YEAR:?Set RUN_YEAR}"

ARCHIVE="${RESTART_ARCHIVE}/${PREV_YEAR}"
[[ -d "${ARCHIVE}" ]] || { echo "ERROR: no restart archive at ${ARCHIVE}"; exit 1; }

cd "${CASE_DIR}"

shopt -s nullglob
WRF_RST=( "${ARCHIVE}"/wrfrst_d0* )
[[ ${#WRF_RST[@]} -gt 0 ]] || { echo "ERROR: no wrfrst files in ${ARCHIVE}"; exit 1; }

for src in "${WRF_RST[@]}"; do
  ln -sf "${src}" "$(basename "${src}")"
  echo "Linked $(basename "${src}")"
done

HYDRO_RST=( "${ARCHIVE}"/HYDRO_RST* "${ARCHIVE}"/RESTART* )
for src in "${HYDRO_RST[@]}"; do
  [[ -f "${src}" ]] || continue
  mkdir -p RESTART
  ln -sf "${src}" "RESTART/$(basename "${src}")"
  echo "Linked RESTART/$(basename "${src}")"
done

echo "Restart files ready in ${CASE_DIR} for RUN_YEAR=${RUN_YEAR}"
