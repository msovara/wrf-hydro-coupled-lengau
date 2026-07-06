#!/bin/bash
# Patch the WRF-Hydro install hydro.namelist for coupled WRF runs.
# Usage: patch_hydro_namelist.sh [hydro.namelist]
set -euo pipefail

HYDRO_NL="${1:-./hydro.namelist}"

[[ -f "${HYDRO_NL}" ]] || { echo "ERROR: ${HYDRO_NL} not found"; exit 1; }

cp -f "${HYDRO_NL}" "${HYDRO_NL}.orig"

# Coupled to WRF (not offline HRLDAS)
sed -i 's/^[[:space:]]*sys_cpl[[:space:]]*=.*/sys_cpl = 2/' "${HYDRO_NL}"

# Required for coupled WRF-Hydro
sed -i 's/^[[:space:]]*SPLIT_OUTPUT_COUNT[[:space:]]*=.*/SPLIT_OUTPUT_COUNT = 1/' "${HYDRO_NL}"

# Hourly routing / LSM interface outputs for water balance
sed -i 's/^[[:space:]]*out_dt[[:space:]]*=.*/out_dt = 60/' "${HYDRO_NL}"
sed -i 's/^[[:space:]]*LSMOUT_DOMAIN[[:space:]]*=.*/LSMOUT_DOMAIN = 1/' "${HYDRO_NL}"
sed -i 's/^[[:space:]]*RTOUT_DOMAIN[[:space:]]*=.*/RTOUT_DOMAIN = 1/' "${HYDRO_NL}"
sed -i 's/^[[:space:]]*CHRTOUT_DOMAIN[[:space:]]*=.*/CHRTOUT_DOMAIN = 1/' "${HYDRO_NL}"
sed -i 's/^[[:space:]]*output_gw[[:space:]]*=.*/output_gw = 1/' "${HYDRO_NL}"

# Cold start: comment any preset restart file from the install template
sed -i 's/^[[:space:]]*RESTART_FILE[[:space:]]*=/!RESTART_FILE =/' "${HYDRO_NL}"

echo "Patched ${HYDRO_NL} for coupled WRF (sys_cpl=2). Backup: ${HYDRO_NL}.orig"
