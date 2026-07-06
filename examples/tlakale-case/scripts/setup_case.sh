#!/bin/bash
# Create Inkomati Phase 1 case directories and link WRF/Hydro table files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

module purge
module load "${WRF_MODULE}"

mkdir -p "${CASE_DIR}"/{DOMAIN,RESTART,FORCING}
mkdir -p "${WPS_CASE_DIR}"

echo "=== Linking WRF run-time tables ==="
shopt -s nullglob
for tbl in "${WRF_ROOT}/run"/*.TBL; do
  ln -sf "${tbl}" "${CASE_DIR}/$(basename "${tbl}")"
done

ln -sf "${WRF_ROOT}/run/URBPARM.TBL" "${CASE_DIR}/URBPARAM.TBL" 2>/dev/null || true

echo "=== Linking WRF-Hydro tables ==="
HYDRO_SHARE="${WRF_ROOT}/share/wrf-hydro"
for f in HYDRO.TBL CHANPARM.TBL MPTABLE.TBL GENPARM.TBL SOILPARM.TBL VEGPARM.TBL; do
  [[ -f "${HYDRO_SHARE}/${f}" ]] && ln -sf "${HYDRO_SHARE}/${f}" "${CASE_DIR}/${f}"
done

cp -f "${HYDRO_SHARE}/hydro.namelist" "${CASE_DIR}/hydro.namelist"
bash "${SCRIPT_DIR}/patch_hydro_namelist.sh" "${CASE_DIR}/hydro.namelist"

echo "=== Copying namelist templates ==="
cp -f "${EXAMPLE_DIR}/namelists/namelist.input.test" "${CASE_DIR}/namelist.input.test"
cp -f "${EXAMPLE_DIR}/namelists/namelist.input.year" "${CASE_DIR}/namelist.input.year"
cp -f "${EXAMPLE_DIR}/namelists/namelist.wps.test" "${WPS_CASE_DIR}/namelist.wps.test"
cp -f "${EXAMPLE_DIR}/namelists/namelist.wps.year" "${WPS_CASE_DIR}/namelist.wps.year"
cp -f "${EXAMPLE_DIR}/namelists/namelist.hrldas.noahmp" "${CASE_DIR}/namelist.hrldas.noahmp"
cp -f "${EXAMPLE_DIR}/namelists/namelist.hrldas.noah" "${CASE_DIR}/namelist.hrldas.noah"

ln -sf "${WPS_DIR}/geogrid.exe" "${WPS_CASE_DIR}/geogrid.exe" 2>/dev/null || true
ln -sf "${WPS_DIR}/ungrib.exe" "${WPS_CASE_DIR}/ungrib.exe" 2>/dev/null || true
ln -sf "${WPS_DIR}/metgrid.exe" "${WPS_CASE_DIR}/metgrid.exe" 2>/dev/null || true
ln -sf "${WPS_DIR}/link_grib.csh" "${WPS_CASE_DIR}/link_grib.csh" 2>/dev/null || true

echo "=== Case ready ==="
echo "WRF case : ${CASE_DIR}"
echo "WPS case : ${WPS_CASE_DIR}"
echo "Next: SIM_MODE=test bash ${SCRIPT_DIR}/apply_namelists.sh"
