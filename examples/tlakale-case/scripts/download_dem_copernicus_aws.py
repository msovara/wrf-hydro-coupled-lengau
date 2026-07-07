#!/usr/bin/env python3
"""
Download Copernicus DEM GLO-30 (1 deg tiles) from AWS and merge for WRF-Hydro GIS.

No API key. Large domains download many tiles (~475 for full d01 bbox).

Usage:
  python download_dem_copernicus_aws.py --bounds-file domain_bounds.env --output dem/inkomati_dem.tif

Requires: pip install rasterio requests
"""
from __future__ import annotations

import argparse
import math
import tempfile
from pathlib import Path

import rasterio
from rasterio.merge import merge
import requests

AWS_BASE = "https://copernicus-dem-30m.s3.amazonaws.com"


def tile_key(lat: int, lon: int) -> str:
    ns = "N" if lat >= 0 else "S"
    ew = "E" if lon >= 0 else "W"
    return (
        f"Copernicus_DSM_COG_10_{ns}{abs(lat):02d}_00_{ew}{abs(lon):03d}_00_DEM/"
        f"Copernicus_DSM_COG_10_{ns}{abs(lat):02d}_00_{ew}{abs(lon):03d}_00_DEM.tif"
    )


def load_bounds(bounds_file: Path) -> tuple[float, float, float, float]:
    vals: dict[str, float] = {}
    for line in bounds_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        vals[key.strip()] = float(value.strip())
    return vals["lon_min"], vals["lat_min"], vals["lon_max"], vals["lat_max"]


def needed_tiles(west: float, south: float, east: float, north: float) -> list[tuple[int, int]]:
    lat_min = math.floor(south)
    lat_max = math.floor(north)
    lon_min = math.floor(west)
    lon_max = math.floor(east)
    tiles = []
    for lat in range(lat_min, lat_max + 1):
        for lon in range(lon_min, lon_max + 1):
            tiles.append((lat, lon))
    return tiles


def main() -> None:
    parser = argparse.ArgumentParser(description="Download Copernicus DEM from AWS")
    parser.add_argument("--bounds-file", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("dem/inkomati_dem.tif"))
    parser.add_argument("--cache-dir", type=Path, default=Path("dem/cop30_cache"))
    args = parser.parse_args()

    west, south, east, north = load_bounds(args.bounds_file)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.cache_dir.mkdir(parents=True, exist_ok=True)

    tiles = needed_tiles(west, south, east, north)
    print(f"Copernicus GLO-30 tiles: {len(tiles)}")

    datasets = []
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        for i, (lat, lon) in enumerate(tiles, 1):
            key = tile_key(lat, lon)
            local = args.cache_dir / Path(key).name
            if not local.exists() or local.stat().st_size == 0:
                url = f"{AWS_BASE}/{key}"
                print(f"[{i}/{len(tiles)}] {url}")
                resp = requests.get(url, timeout=120)
                if resp.status_code != 200:
                    print(f"  skip HTTP {resp.status_code}")
                    continue
                local.write_bytes(resp.content)
            datasets.append(rasterio.open(local))

        if not datasets:
            raise SystemExit("No tiles downloaded")

        mosaic, out_transform = merge(datasets)
        meta = datasets[0].meta.copy()
        meta.update(
            height=mosaic.shape[1],
            width=mosaic.shape[2],
            transform=out_transform,
            compress="deflate",
            tiled=True,
        )
        with rasterio.open(args.output, "w", **meta) as dst:
            dst.write(mosaic)

    for ds in datasets:
        ds.close()

    print(f"Saved {args.output} ({args.output.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
