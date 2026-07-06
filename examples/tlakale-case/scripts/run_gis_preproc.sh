#!/bin/bash
# Build WRF-Hydro routing DOMAIN files from geo_em + DEM using NCAR GIS preprocessor.
#
# Prerequisites:
#   1. geo_em.d01.nc in CASE_DIR/DOMAIN/ (run run_geogrid.sh first)
#   2. wrf_hydro_gis cloned to GIS_TOOL_DIR (see setup_gis_env.sh)
#   3. Hydrologically conditioned DEM GeoTIFF in DEM_PATH
#
# Usage:
#   DEM_PATH=/path/to/inkomati_dem.tif bash run_gis_preproc.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

GEOGRID="${CASE_DIR}/DOMAIN/geo_em.d01.nc"
DEM_PATH="${DEM_PATH:?Set DEM_PATH to a conditioned DEM GeoTIFF (metres, WGS84 or projected)}"
GIS_TOOL_DIR="${GIS_TOOL_DIR:-${EXAMPLE_DIR}/gis/wrf_hydro_gis_preprocessor/wrfhydro_gis}"
OUT_ZIP="${CASE_DIR}/DOMAIN/routing_stack.zip"

REGFACT="${GIS_REGFACT:-4}"
THRESHOLD="${GIS_THRESHOLD:-500}"
ROUTING="${GIS_ROUTING:-True}"

[[ -f "${GEOGRID}" ]] || { echo "ERROR: missing ${GEOGRID} — run run_geogrid.sh first"; exit 1; }
[[ -f "${DEM_PATH}" ]] || { echo "ERROR: missing DEM: ${DEM_PATH}"; exit 1; }
[[ -f "${GIS_TOOL_DIR}/Build_Routing_Stack.py" ]] || {
  echo "ERROR: GIS tool not found at ${GIS_TOOL_DIR}"
  echo "Run: bash ${SCRIPT_DIR}/setup_gis_env.sh"
  exit 1
}

# shellcheck source=/dev/null
source "${GIS_CONDA_ENV:-${EXAMPLE_DIR}/gis/activate_gis_env.sh}" 2>/dev/null || true

cd "${GIS_TOOL_DIR}"
echo "=== Build_Routing_Stack ==="
echo "GEOGRID=${GEOGRID}"
echo "DEM=${DEM_PATH}"
echo "REGFACT=${REGFACT} THRESHOLD=${THRESHOLD} ROUTING=${ROUTING}"

python Build_Routing_Stack.py \
  -i "${GEOGRID}" \
  -d "${DEM_PATH}" \
  -R "${REGFACT}" \
  -t "${THRESHOLD}" \
  -r "${ROUTING}" \
  -o "${OUT_ZIP}"

cd "${CASE_DIR}/DOMAIN"
unzip -o "${OUT_ZIP}"
echo "=== DOMAIN files ==="
ls -la
