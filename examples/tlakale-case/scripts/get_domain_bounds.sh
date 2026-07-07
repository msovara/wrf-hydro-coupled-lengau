#!/bin/bash
# Print WGS84 bounding box from geo_em.d01.nc (no netCDF4 Python required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${EXAMPLE_DIR}/config.env"

GEO="${1:-${CASE_DIR}/DOMAIN/geo_em.d01.nc}"
[[ -f "${GEO}" ]] || { echo "ERROR: missing ${GEO}"; exit 1; }

module load chpc/earth/netcdf/4.7.4/gcc-8.3.0 2>/dev/null || true

if command -v ncdump >/dev/null 2>&1; then
  TMP="$(mktemp)"
  trap 'rm -f "${TMP}"' EXIT
  ncdump -v XLAT_M,XLONG_M "${GEO}" > "${TMP}"
  python3 - "${TMP}" << 'PY'
import re, sys
path = sys.argv[1]
lat_vals, lon_vals = [], []
var = None
with open(path) as fh:
    for line in fh:
        if line.strip().startswith("XLAT_M ="):
            var = "lat"
            continue
        if line.strip().startswith("XLONG_M ="):
            var = "lon"
            continue
        if var and (";" in line or re.search(r"-?\d", line)):
            nums = re.findall(r"-?\d+\.?\d*", line)
            (lat_vals if var == "lat" else lon_vals).extend(float(x) for x in nums)
            if ";" in line:
                var = None
if not lat_vals or not lon_vals:
    sys.exit("Could not parse ncdump output")
print(f"lat_min={min(lat_vals):.4f}")
print(f"lat_max={max(lat_vals):.4f}")
print(f"lon_min={min(lon_vals):.4f}")
print(f"lon_max={max(lon_vals):.4f}")
PY
  exit 0
fi

echo "ERROR: ncdump not available; load chpc/earth/netcdf module" >&2
exit 1
