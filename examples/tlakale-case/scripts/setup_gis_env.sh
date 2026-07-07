#!/bin/bash
# Set up WRF-Hydro GIS preprocessor from bundled copy (no internet required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
GIS_ROOT="${EXAMPLE_DIR}/gis"
BUNDLE="${GIS_ROOT}/wrf_hydro_gis_preprocessor"

if [[ ! -d "${BUNDLE}/wrfhydro_gis" ]]; then
  echo "ERROR: Bundled GIS tool not found at ${BUNDLE}"
  echo "On a PC with internet, from tlakale-case/gis run:"
  echo "  git clone --depth 1 https://github.com/NCAR/wrf_hydro_gis_preprocessor.git"
  echo "Then scp the whole tlakale-case folder to Lengau."
  exit 1
fi

module load chpc/python/anaconda/3-2024.10.1 2>/dev/null || true

if ! conda env list 2>/dev/null | grep -q wrfh_gis_env; then
  echo "Creating conda env wrfh_gis_env (needs conda channels cached or offline mirror)..."
  conda create -y -n wrfh_gis_env -c conda-forge \
    python=3.10 gdal=3.6.3 netCDF4=1.6.3 numpy=1.24.2 pyproj=3.4.1 \
    whitebox=2.3.5 packaging=23.0 shapely=2.0.1 || {
    echo "WARN: conda create failed (offline?). Run GIS on your PC instead:"
    echo "  python scripts/run_gis_preproc_local.py --geo-em geo_em.d01.nc --dem dem/inkomati_dem.tif"
    echo "  scp DOMAIN/*.nc to cases/my_hydro_run/DOMAIN/ on Lengau"
  }
fi

GIS_ENV=""
if conda env list 2>/dev/null | grep -q wrfh_gis_env; then
  GIS_ENV="wrfh_gis_env"
elif conda env list 2>/dev/null | grep -qE '/grib_env|grib_env'; then
  echo "NOTE: wrfh_gis_env missing; trying grib_env if GDAL present."
  GIS_ENV="grib_env"
fi

cat > "${GIS_ROOT}/activate_gis_env.sh" << EOF
module load chpc/python/anaconda/3-2024.10.1 2>/dev/null || true
source "\$(conda info --base)/etc/profile.d/conda.sh"
if conda env list 2>/dev/null | grep -q wrfh_gis_env; then
  conda activate wrfh_gis_env
elif conda env list 2>/dev/null | grep -q grib_env; then
  conda activate grib_env
else
  echo "ERROR: no GIS conda env. Build routing stack on PC (run_gis_preproc_local.py)."
  exit 1
fi
export GIS_TOOL_DIR="${BUNDLE}/wrfhydro_gis"
EOF

echo "GIS tools: ${BUNDLE}/wrfhydro_gis"
echo "Activate: source ${GIS_ROOT}/activate_gis_env.sh"
