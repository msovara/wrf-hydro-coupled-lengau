#!/bin/bash
# Submit Phase 1 yearly runs (1980–2010) with PBS job dependencies.
#
# Usage:
#   bash run_phase1_years.sh              # print commands
#   bash run_phase1_years.sh submit       # submit chained WRF jobs
#   bash run_phase1_years.sh submit-all   # submit WPS+real+WRF per year (chained)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

ACTION="${1:-dry-run}"
PREV_JOB=""

for YEAR in $(seq "${PHASE1_START_YEAR}" "${PHASE1_END_YEAR}"); do
  if [[ "${YEAR}" -eq "${PHASE1_START_YEAR}" ]]; then
    RESTART=false
    PREV_YEAR=""
  else
    RESTART=true
    PREV_YEAR=$((YEAR - 1))
  fi

  VARS="SIM_MODE=year,RUN_YEAR=${YEAR},RESTART=${RESTART}"
  [[ -n "${PREV_YEAR}" ]] && VARS="${VARS},PREV_YEAR=${PREV_YEAR}"

  if [[ "${ACTION}" == "submit-all" ]]; then
    if [[ -n "${PREV_JOB}" ]]; then
      WPS_ID=$(qsub -W "depend=afterok:${PREV_JOB}" -N "tlakale_wps_${YEAR}" -v "${VARS}" "${SCRIPT_DIR}/run_wps.pbs")
    else
      WPS_ID=$(qsub -N "tlakale_wps_${YEAR}" -v "${VARS}" "${SCRIPT_DIR}/run_wps.pbs")
    fi
    REAL_ID=$(qsub -W "depend=afterok:${WPS_ID}" -N "tlakale_real_${YEAR}" -v "${VARS}" "${SCRIPT_DIR}/run_real.pbs")
    WRF_ID=$(qsub -W "depend=afterok:${REAL_ID}" -N "tlakale_wrf_${YEAR}" -v "${VARS}" "${SCRIPT_DIR}/run_wrf.pbs")
    echo "Submitted ${YEAR}: wps=${WPS_ID} real=${REAL_ID} wrf=${WRF_ID}"
    PREV_JOB="${WRF_ID}"
  elif [[ "${ACTION}" == "submit" ]]; then
    if [[ -n "${PREV_JOB}" ]]; then
      PREV_JOB=$(qsub -W "depend=afterok:${PREV_JOB}" -N "tlakale_wrf_${YEAR}" -v "${VARS}" "${SCRIPT_DIR}/run_wrf.pbs")
    else
      PREV_JOB=$(qsub -N "tlakale_wrf_${YEAR}" -v "${VARS}" "${SCRIPT_DIR}/run_wrf.pbs")
    fi
    echo "Submitted WRF ${YEAR}: ${PREV_JOB} (RESTART=${RESTART})"
  else
    echo "qsub -v ${VARS} -N tlakale_wrf_${YEAR} ${SCRIPT_DIR}/run_wrf.pbs"
  fi
done

echo ""
echo "Phase 1 period: ${PHASE1_START_YEAR}–${PHASE1_END_YEAR}"
