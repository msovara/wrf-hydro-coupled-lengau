#!/bin/bash
# Apply test or yearly namelists to the case directory.
#   SIM_MODE=test  bash apply_namelists.sh
#   SIM_MODE=year RUN_YEAR=1980 RESTART=false bash apply_namelists.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

SIM_MODE="${SIM_MODE:-test}"
RUN_YEAR="${RUN_YEAR:-1980}"
RESTART="${RESTART:-false}"
LSM_OPTION="${LSM_OPTION:-noahmp}"

if [[ "${RESTART}" == "true" ]]; then
  RESTART_F=".true."
else
  RESTART_F=".false."
fi

apply_sed() {
  local src="$1" dst="$2"
  sed -e "s|__YEAR__|${RUN_YEAR}|g" \
      -e "s|__GEOG_DATA_PATH__|${GEOG_DATA_PATH}|g" \
      -e "s|__RESTART__|${RESTART_F}|g" \
      "${src}" > "${dst}"
}

case "${SIM_MODE}" in
  test)
    RUN_YEAR=2010
    cp -f "${CASE_DIR}/namelist.input.test" "${CASE_DIR}/namelist.input"
    apply_sed "${WPS_CASE_DIR}/namelist.wps.test" "${WPS_CASE_DIR}/namelist.wps"
    apply_sed "${CASE_DIR}/namelist.hrldas.noahmp" "${CASE_DIR}/namelist.hrldas"
    ;;
  year)
    apply_sed "${CASE_DIR}/namelist.input.year" "${CASE_DIR}/namelist.input"
    apply_sed "${WPS_CASE_DIR}/namelist.wps.year" "${WPS_CASE_DIR}/namelist.wps"
    apply_sed "${CASE_DIR}/namelist.hrldas.noahmp" "${CASE_DIR}/namelist.hrldas"
    ;;
  *)
    echo "ERROR: SIM_MODE must be 'test' or 'year' (got ${SIM_MODE})"
    exit 1
    ;;
esac

if [[ "${LSM_OPTION}" == "noah" ]]; then
  sed -i 's/sf_surface_physics[[:space:]]*=[[:space:]]*5,[[:space:]]*5,/sf_surface_physics                  =  2,     2,/' "${CASE_DIR}/namelist.input"
  apply_sed "${CASE_DIR}/namelist.hrldas.noah" "${CASE_DIR}/namelist.hrldas"
fi

echo "Applied SIM_MODE=${SIM_MODE} RUN_YEAR=${RUN_YEAR} RESTART=${RESTART}"
echo "  ${CASE_DIR}/namelist.input"
echo "  ${WPS_CASE_DIR}/namelist.wps"
echo "  ${CASE_DIR}/namelist.hrldas"
