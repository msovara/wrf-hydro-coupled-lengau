#!/bin/bash
# Patch hydro.namelist for Phase 1 coupled WRF-Hydro water-balance runs.
# Usage: patch_hydro_namelist.sh [hydro.namelist]
set -euo pipefail

HYDRO_NL="${1:-./hydro.namelist}"

[[ -f "${HYDRO_NL}" ]] || { echo "ERROR: ${HYDRO_NL} not found"; exit 1; }

[[ -f "${HYDRO_NL}.orig" ]] || cp -f "${HYDRO_NL}" "${HYDRO_NL}.orig"

# Coupled to WRF (not offline HRLDAS)
sed -i 's/^[[:space:]]*sys_cpl[[:space:]]*=.*/sys_cpl = 2/' "${HYDRO_NL}"

# Required for coupled WRF-Hydro
sed -i 's/^[[:space:]]*SPLIT_OUTPUT_COUNT[[:space:]]*=.*/SPLIT_OUTPUT_COUNT = 1/' "${HYDRO_NL}"

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

# Cold start unless wrf/hydro restart files are linked for the run year
if [[ "${RESTART:-false}" == "true" ]]; then
  sed -i 's/^[[:space:]]*!RESTART_FILE/RESTART_FILE/' "${HYDRO_NL}"
else
  sed -i 's/^[[:space:]]*RESTART_FILE[[:space:]]*=/!RESTART_FILE =/' "${HYDRO_NL}"
fi

echo "Patched ${HYDRO_NL} for Phase 1 coupled WRF-Hydro. Backup: ${HYDRO_NL}.orig"
