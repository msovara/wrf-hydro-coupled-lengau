#!/bin/bash
# Prepare Jan 2010 test continuation from latest wrfrst in the case dir.
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

latest_d01="$(ls -1 wrfrst_d01_* 2>/dev/null | sort | tail -1)"
[[ -n "${latest_d01}" ]] || { echo "ERROR: no wrfrst_d01_* in ${CASE_DIR}"; exit 1; }

# wrfrst_d01_2010-01-21_00:00:00
rst_stamp="${latest_d01#wrfrst_d01_}"
RST_YEAR="${rst_stamp:0:4}"
RST_MONTH="${rst_stamp:5:2}"
RST_DAY="${rst_stamp:8:2}"
RST_HOUR="${rst_stamp:11:2}"

NL="${CASE_DIR}/namelist.input"
[[ -f "${NL}" ]] || { echo "ERROR: ${NL} not found"; exit 1; }

sed -i \
  -e "s/^[[:space:]]*start_year[[:space:]]*=.*/ start_year                          = ${RST_YEAR}, ${RST_YEAR},/" \
  -e "s/^[[:space:]]*start_month[[:space:]]*=.*/ start_month                         = ${RST_MONTH},   ${RST_MONTH},/" \
  -e "s/^[[:space:]]*start_day[[:space:]]*=.*/ start_day                           = ${RST_DAY},   ${RST_DAY},/" \
  -e "s/^[[:space:]]*start_hour[[:space:]]*=.*/ start_hour                          = ${RST_HOUR},   ${RST_HOUR},/" \
  "${NL}"

echo "Updated ${NL} start time to ${RST_YEAR}-${RST_MONTH}-${RST_DAY}_${RST_HOUR}:00:00 from ${latest_d01}"

if [[ -d RESTART ]]; then
  shopt -s nullglob
  HYDRO_RST=( RESTART/HYDRO_RST* RESTART/RESTART* )
  if (( ${#HYDRO_RST[@]} > 0 )); then
    for f in "${HYDRO_RST[@]}"; do
      echo "Found hydro restart: ${f}"
    done
  else
    echo "NOTE: no hydro restart files in ${CASE_DIR}/RESTART (continuing with WRF wrfrst only)"
  fi
fi

echo "Restart files ready in ${CASE_DIR} for SIM_MODE=test RESTART=true"
