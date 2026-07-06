#!/usr/bin/env python3
"""Print WRF geo_em domain bounding box (WGS84) for DEM download."""
import sys
from netCDF4 import Dataset

geo = sys.argv[1] if len(sys.argv) > 1 else "geo_em.d01.nc"
with Dataset(geo) as ds:
    lat = ds.variables["XLAT_M"][0]
    lon = ds.variables["XLONG_M"][0]
    print(f"lat_min={float(lat.min()):.4f}")
    print(f"lat_max={float(lat.max()):.4f}")
    print(f"lon_min={float(lon.min()):.4f}")
    print(f"lon_max={float(lon.max()):.4f}")
