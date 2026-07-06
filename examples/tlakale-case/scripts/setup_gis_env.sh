#!/bin/bash
# Clone WRF-Hydro GIS preprocessor and create conda env (run on DTN or machine with internet).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
GIS_ROOT="${EXAMPLE_DIR}/gis"

mkdir -p "${GIS_ROOT}"
cd "${GIS_ROOT}"

if [[ ! -d wrf_hydro_gis_preprocessor ]]; then
  git clone https://github.com/NCAR/wrf_hydro_gis_preprocessor.git
fi

module load chpc/python/anaconda/3-2024.10.1 2>/dev/null || true

if ! conda env list | grep -q wrfh_gis_env; then
  conda create -y -n wrfh_gis_env -c conda-forge \
    python=3.10 gdal=3.6.3 netCDF4=1.6.3 numpy=1.24.2 pyproj=3.4.1 \
    whitebox=2.3.5 packaging=23.0 shapely=2.0.1
fi

cat > "${GIS_ROOT}/activate_gis_env.sh" << 'EOF'
module load chpc/python/anaconda/3-2024.10.1 2>/dev/null || true
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate wrfh_gis_env
export GIS_TOOL_DIR="${GIS_TOOL_DIR:-$(dirname "$0")/wrf_hydro_gis_preprocessor/wrfhydro_gis}"
EOF

echo "GIS tools ready under ${GIS_ROOT}"
echo "Activate: source ${GIS_ROOT}/activate_gis_env.sh"
