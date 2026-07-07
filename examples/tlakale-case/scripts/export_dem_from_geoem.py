#!/usr/bin/env python3
"""
Export geo_em HGT_M to GeoTIFF as interim DEM for GIS routing-stack testing.

Not hydrologically conditioned — replace with MERIT/Copernicus DEM for production.

Usage:
  python export_dem_from_geoem.py geo_em.d01.nc --output dem/inkomati_dem_geoem.tif
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import rasterio
from rasterio.transform import from_bounds
from netCDF4 import Dataset


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("geo_em", type=Path)
    parser.add_argument("--output", type=Path, default=Path("dem/inkomati_dem_geoem.tif"))
    args = parser.parse_args()

    with Dataset(args.geo_em) as ds:
        hgt = ds.variables["HGT_M"][0, :, :]
        lat = ds.variables["XLAT_M"][0, :, :]
        lon = ds.variables["XLONG_M"][0, :, :]

    data = np.array(hgt, dtype=np.float32)
    south, north = float(lat.min()), float(lat.max())
    west, east = float(lon.min()), float(lon.max())
    transform = from_bounds(west, south, east, north, data.shape[1], data.shape[0])

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with rasterio.open(
        args.output,
        "w",
        driver="GTiff",
        height=data.shape[0],
        width=data.shape[1],
        count=1,
        dtype="float32",
        crs="EPSG:4326",
        transform=transform,
        compress="deflate",
    ) as dst:
        dst.write(data, 1)

    print(f"Saved {args.output} ({args.output.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
