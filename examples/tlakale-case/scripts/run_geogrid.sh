#!/bin/bash
# Generate geo_em.d0*.nc via geogrid (no ERA5 required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

SIM_MODE="${SIM_MODE:-test}"
mkdir -p "${WPS_CASE_DIR}" "${CASE_DIR}/DOMAIN"

if [[ "${SIM_MODE}" == "test" ]]; then
  sed -e "s|__GEOG_DATA_PATH__|${GEOG_DATA_PATH}|g" \
      -e "s|__YEAR__|${TEST_YEAR}|g" \
      "${EXAMPLE_DIR}/namelists/namelist.wps.test" > "${WPS_CASE_DIR}/namelist.wps"
else
  RUN_YEAR="${RUN_YEAR:-${PHASE1_START_YEAR}}"
  sed -e "s|__GEOG_DATA_PATH__|${GEOG_DATA_PATH}|g" \
      -e "s|__YEAR__|${RUN_YEAR}|g" \
      "${EXAMPLE_DIR}/namelists/namelist.wps.year" > "${WPS_CASE_DIR}/namelist.wps"
fi

module purge
module load "${WRF_MODULE}"

cd "${WPS_CASE_DIR}"
ln -sf "${WPS_DIR}/geogrid.exe" ./geogrid.exe
mkdir -p geogrid
ln -sf "${WPS_ROOT}/geogrid/GEOGRID.TBL" ./geogrid/GEOGRID.TBL
ln -sf "${WPS_ROOT}/geogrid/GEOGRID.TBL" ./GEOGRID.TBL

echo "=== geogrid ==="
if [[ -n "${PBS_JOBID:-}" ]]; then
  mpirun -np "${NP_WPS:-1}" ./geogrid.exe
else
  ./geogrid.exe
fi

shopt -s nullglob
geo_files=(geo_em.d0*.nc)
if [[ ${#geo_files[@]} -eq 0 ]]; then
  echo "ERROR: geogrid did not produce geo_em files — check geogrid.log"
  exit 1
fi

for f in "${geo_files[@]}"; do
  cp -f "${f}" "${CASE_DIR}/DOMAIN/${f}"
  echo "Copied ${f} -> ${CASE_DIR}/DOMAIN/"
done

ls -la "${CASE_DIR}/DOMAIN/"
