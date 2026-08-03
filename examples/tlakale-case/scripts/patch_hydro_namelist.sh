#!/bin/bash
# Patch hydro.namelist for Phase 1 coupled WRF-Hydro water-balance runs.
# Usage: patch_hydro_namelist.sh [hydro.namelist]
set -euo pipefail

HYDRO_NL="${1:-./hydro.namelist}"

[[ -f "${HYDRO_NL}" ]] || { echo "ERROR: ${HYDRO_NL} not found"; exit 1; }

[[ -f "${HYDRO_NL}.orig" ]] || cp -f "${HYDRO_NL}" "${HYDRO_NL}.orig"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [[ -f "${EXAMPLE_DIR}/config.env" ]]; then
  # shellcheck source=/dev/null
  source "${EXAMPLE_DIR}/config.env"
fi
CASE_DIR="${CASE_DIR:-$(dirname "${HYDRO_NL}")}"

# Coupled to WRF (not offline HRLDAS)
sed -i 's/^[[:space:]]*sys_cpl[[:space:]]*=.*/sys_cpl = 2/' "${HYDRO_NL}"

# Required for coupled WRF-Hydro
sed -i 's/^[[:space:]]*SPLIT_OUTPUT_COUNT[[:space:]]*=.*/SPLIT_OUTPUT_COUNT = 1/' "${HYDRO_NL}"

# Channel routing (Route_Link.nc must be active for CHRTOUT)
sed -i 's|^[[:space:]]*!*[[:space:]]*route_link_f[[:space:]]*=.*|route_link_f = "./DOMAIN/Route_Link.nc"|' "${HYDRO_NL}"

# Phase 1 water-balance output: hourly (test) or 3-hourly (year/production)
SIM_MODE="${SIM_MODE:-test}"
if [[ "${SIM_MODE}" == "year" ]]; then
  HYDRO_OUT_DT="${HYDRO_OUT_DT_YEAR:-180}"
else
  HYDRO_OUT_DT="${HYDRO_OUT_DT_TEST:-60}"
fi
sed -i "s/^[[:space:]]*out_dt[[:space:]]*=.*/out_dt = ${HYDRO_OUT_DT}/" "${HYDRO_NL}"
sed -i 's/^[[:space:]]*rst_dt[[:space:]]*=.*/rst_dt = 1440/' "${HYDRO_NL}"
sed -i 's/^[[:space:]]*LSMOUT_DOMAIN[[:space:]]*=.*/LSMOUT_DOMAIN = 1/' "${HYDRO_NL}"
sed -i 's/^[[:space:]]*RTOUT_DOMAIN[[:space:]]*=.*/RTOUT_DOMAIN = 1/' "${HYDRO_NL}"
sed -i 's/^[[:space:]]*CHRTOUT_DOMAIN[[:space:]]*=.*/CHRTOUT_DOMAIN = 1/' "${HYDRO_NL}"
sed -i 's/^[[:space:]]*output_gw[[:space:]]*=.*/output_gw = 1/' "${HYDRO_NL}"
sed -i 's/^[[:space:]]*output_channelBucket_influx[[:space:]]*=.*/output_channelBucket_influx = 1/' "${HYDRO_NL}"

# Routing on d01 (regional); adjust IGRID if routing targets d02 nest
sed -i 's/^[[:space:]]*IGRID[[:space:]]*=.*/IGRID = 1/' "${HYDRO_NL}"

# Hydro / GW restart: only when a HYDRO_RST file exists in RESTART/
HYDRO_RST_PATH=""
if [[ -d "${CASE_DIR}/RESTART" ]]; then
  shopt -s nullglob
  _hydro_rst=( "${CASE_DIR}"/RESTART/HYDRO_RST* )
  if (( ${#_hydro_rst[@]} > 0 )); then
    _latest="$(printf '%s\n' "${_hydro_rst[@]}" | sort | tail -1)"
    HYDRO_RST_PATH="./RESTART/$(basename "${_latest}")"
  fi
fi

if [[ "${RESTART:-false}" == "true" && -n "${HYDRO_RST_PATH}" ]]; then
  sed -i "s|^[[:space:]]*!*[[:space:]]*RESTART_FILE[[:space:]]*=.*|RESTART_FILE = '${HYDRO_RST_PATH}'|" "${HYDRO_NL}"
  sed -i 's/^[[:space:]]*GW_RESTART[[:space:]]*=.*/GW_RESTART = 1/' "${HYDRO_NL}"
  echo "Hydro restart: ${HYDRO_RST_PATH}"
else
  sed -i 's/^[[:space:]]*!*[[:space:]]*RESTART_FILE[[:space:]]*=.*$/!RESTART_FILE =/' "${HYDRO_NL}"
  sed -i 's/^[[:space:]]*GW_RESTART[[:space:]]*=.*/GW_RESTART = 0/' "${HYDRO_NL}"
  echo "Hydro cold start (RESTART_FILE commented, GW_RESTART=0)"
fi

echo "Patched ${HYDRO_NL} for Phase 1 coupled WRF-Hydro. Backup: ${HYDRO_NL}.orig"
