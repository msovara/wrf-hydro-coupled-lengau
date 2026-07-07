#!/usr/bin/env python3
"""
Download MERIT DEM 3 arc-sec tiles (5 deg x 5 deg) and merge for WRF-Hydro GIS.

No API key required. Tiles from U-Tokyo MERIT Hydro server.

Usage:
  python download_dem_merit.py --bounds-file domain_bounds.env --output dem/inkomati_dem.tif

Requires: pip install rasterio numpy requests
"""
from __future__ import annotations

import argparse
import math
import tempfile
from pathlib import Path

import numpy as np
import rasterio
from rasterio.merge import merge
from rasterio.transform import from_origin
import requests


MERIT_BASE = "http://hydro.iis.u-tokyo.ac.jp/~yamadai/MERIT_DEM/1_sec/float"


def tile_name(lat_sw: int, lon_sw: int) -> str:
    ns = f"n{abs(lat_sw):02d}" if lat_sw >= 0 else f"s{abs(lat_sw):02d}"
    ew = f"e{abs(lon_sw):03d}" if lon_sw >= 0 else f"w{abs(lon_sw):03d}"
    return f"{ns}{ew}"


def load_bounds(bounds_file: Path) -> tuple[float, float, float, float]:
    vals: dict[str, float] = {}
    for line in bounds_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        vals[key.strip()] = float(value.strip())
    return vals["lon_min"], vals["lat_min"], vals["lon_max"], vals["lat_max"]


def merit_tiles(west: float, south: float, east: float, north: float) -> list[tuple[int, int]]:
    lat_start = math.floor(south / 5) * 5
    lat_end = math.floor((north - 1e-6) / 5) * 5
    lon_start = math.floor(west / 5) * 5
    lon_end = math.floor((east - 1e-6) / 5) * 5
    tiles = []
    lat = lat_start
    while lat <= lat_end:
        lon = lon_start
        while lon <= lon_end:
            tiles.append((lat, lon))
            lon += 5
        lat += 5
    return tiles


def download_tile(lat_sw: int, lon_sw: int, cache_dir: Path) -> Path | None:
    name = tile_name(lat_sw, lon_sw)
    out = cache_dir / f"{name}.flt"
    if out.exists() and out.stat().st_size > 0:
        return out
    url = f"{MERIT_BASE}/{name}.flt"
    print(f"Downloading {url}")
    resp = requests.get(url, timeout=300)
    if resp.status_code != 200:
        print(f"  WARN: HTTP {resp.status_code} for {name}")
        return None
    out.write_bytes(resp.content)
    return out


def flt_to_dataset(flt_path: Path, lat_sw: int, lon_sw: int):
    # MERIT 1 arc-sec float, 5 deg tile = 18000 x 18000 pixels
    n = 18000
    data = np.fromfile(flt_path, dtype=np.float32).reshape(n, n)
    data = np.where(data < -1e4, np.nan, data)
    west = lon_sw
    north = lat_sw + 5
    transform = from_origin(west, north, 1 / 3600, 1 / 3600)
    return data, transform


def main() -> None:
    parser = argparse.ArgumentParser(description="Download MERIT DEM tiles")
    parser.add_argument("--bounds-file", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("dem/inkomati_dem.tif"))
    parser.add_argument("--cache-dir", type=Path, default=Path("dem/merit_cache"))
    args = parser.parse_args()

    west, south, east, north = load_bounds(args.bounds_file)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.cache_dir.mkdir(parents=True, exist_ok=True)

    tiles = merit_tiles(west, south, east, north)
    print(f"MERIT tiles needed: {len(tiles)} ({tiles})")

    datasets = []
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        for lat_sw, lon_sw in tiles:
            flt = download_tile(lat_sw, lon_sw, args.cache_dir)
            if flt is None:
                continue
            data, transform = flt_to_dataset(flt, lat_sw, lon_sw)
            mem = tmp_path / f"{tile_name(lat_sw, lon_sw)}.tif"
            with rasterio.open(
                mem,
                "w",
                driver="GTiff",
                height=data.shape[0],
                width=data.shape[1],
                count=1,
                dtype="float32",
                crs="EPSG:4326",
                transform=transform,
                nodata=np.nan,
            ) as dst:
                dst.write(data, 1)
            datasets.append(rasterio.open(mem))

        if not datasets:
            raise SystemExit("No MERIT tiles downloaded")

        mosaic, out_transform = merge(datasets)
        meta = datasets[0].meta.copy()
        meta.update(
            height=mosaic.shape[1],
            width=mosaic.shape[2],
            transform=out_transform,
            compress="deflate",
        )
        with rasterio.open(args.output, "w", **meta) as dst:
            dst.write(mosaic)

    size_mb = args.output.stat().st_size / (1024 * 1024)
    print(f"Saved {args.output} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
