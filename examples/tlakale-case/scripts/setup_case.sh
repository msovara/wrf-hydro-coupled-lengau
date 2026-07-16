#!/bin/bash
# Create Phase 1 case directories and link WRF/Hydro tables (new cases only).
# Existing cases (e.g. my_hydro_run): use apply_namelists.sh instead.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

module purge
module load "${WRF_MODULE}"

mkdir -p "${CASE_DIR}"/{DOMAIN,RESTART} "${WPS_CASE_DIR}" "${RESTART_ARCHIVE}"

WRF_RUN="${WRF_RUN:-${WRF_ROOT}/build/WRF/run}"
[[ -d "${WRF_RUN}" ]] || WRF_RUN="${WRF_ROOT}/run"

echo "=== Linking WRF run-time tables and auxiliary data ==="
shopt -s nullglob
for tbl in "${WRF_RUN}"/*.TBL; do
  ln -sf "${tbl}" "${CASE_DIR}/$(basename "${tbl}")"
done

# WRF 4.4+ CONUS/RRTMG needs these in the case directory (not just .TBL files).
ln -sf "${WRF_RUN}/CAMtr_volume_mixing_ratio.RCP4.5" "${CASE_DIR}/CAMtr_volume_mixing_ratio"
for aux in ozone.formatted ozone_lat.formatted ozone_plev.formatted \
             RRTMG_LW_DATA RRTMG_SW_DATA RRTMG_LW_DATA_DBL RRTMG_SW_DATA_DBL; do
  [[ -f "${WRF_RUN}/${aux}" ]] && ln -sf "${WRF_RUN}/${aux}" "${CASE_DIR}/${aux}"
done
for clm in "${WRF_RUN}"/CLM_*; do
  [[ -f "${clm}" ]] && ln -sf "${clm}" "${CASE_DIR}/$(basename "${clm}")"
done

HYDRO_SHARE="${WRF_ROOT}/share/wrf-hydro"
for f in HYDRO.TBL CHANPARM.TBL MPTABLE.TBL GENPARM.TBL SOILPARM.TBL VEGPARM.TBL; do
  [[ -f "${HYDRO_SHARE}/${f}" ]] && ln -sf "${HYDRO_SHARE}/${f}" "${CASE_DIR}/${f}"
done

if [[ ! -f "${CASE_DIR}/hydro.namelist" ]]; then
  cp -f "${HYDRO_SHARE}/hydro.namelist" "${CASE_DIR}/hydro.namelist"
fi
bash "${SCRIPT_DIR}/patch_hydro_namelist.sh" "${CASE_DIR}/hydro.namelist"

ln -sf "${WPS_DIR}/geogrid.exe" "${WPS_CASE_DIR}/geogrid.exe" 2>/dev/null || true
ln -sf "${WPS_DIR}/ungrib.exe" "${WPS_CASE_DIR}/ungrib.exe" 2>/dev/null || true
ln -sf "${WPS_DIR}/metgrid.exe" "${WPS_CASE_DIR}/metgrid.exe" 2>/dev/null || true
ln -sf "${WPS_DIR}/link_grib.csh" "${WPS_CASE_DIR}/link_grib.csh" 2>/dev/null || true

echo "=== Phase 1 case ready ==="
echo "WRF : ${CASE_DIR}"
echo "WPS : ${WPS_CASE_DIR}"
echo "Next: SIM_MODE=test bash ${SCRIPT_DIR}/apply_namelists.sh"
