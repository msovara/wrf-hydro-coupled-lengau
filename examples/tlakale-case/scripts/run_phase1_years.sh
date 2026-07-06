#!/bin/bash
# Submit Phase 1 yearly runs (1980–2010) one year at a time with restarts.
# Usage:
#   bash run_phase1_years.sh           # dry-run (print qsub commands)
#   bash run_phase1_years.sh submit    # submit all years
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

START_YEAR=1980
END_YEAR=2010
ACTION="${1:-dry-run}"

for YEAR in $(seq "${START_YEAR}" "${END_YEAR}"); do
  if [[ "${YEAR}" -eq "${START_YEAR}" ]]; then
    RESTART=false
  else
    RESTART=true
  fi

  CMD=(qsub -v "SIM_MODE=year,RUN_YEAR=${YEAR},RESTART=${RESTART}"
       -N "tlakale_${YEAR}"
       "${SCRIPT_DIR}/run_wrf.pbs")

  if [[ "${ACTION}" == "submit" ]]; then
    echo "Submitting ${YEAR} (RESTART=${RESTART})..."
    "${CMD[@]}"
  else
    echo "${CMD[*]}"
  fi
done

echo ""
echo "Note: chain jobs with depend=afterok if you need strict year ordering."
echo "      Copy wrfout/wrfinput restart from year N to initialize year N+1."
