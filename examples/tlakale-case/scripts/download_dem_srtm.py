#!/usr/bin/env python3
"""
Download SRTM30 DEM for WRF-Hydro GIS (local PC, no API key).

Requires: pip install elevation rasterio

Usage:
  python download_dem_srtm.py --bounds-file domain_bounds.env

Note: For production routing, prefer MERIT or Copernicus conditioned DEM.
SRTM is sufficient for initial routing-stack build and workflow testing.
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def load_bounds(bounds_file: Path) -> tuple[float, float, float, float]:
    vals: dict[str, float] = {}
    for line in bounds_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        vals[key.strip()] = float(value.strip())
    pad = 0.25
    return (
        vals["lon_min"] - pad,
        vals["lat_min"] - pad,
        vals["lon_max"] + pad,
        vals["lat_max"] + pad,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Download SRTM30 DEM via elevation")
    parser.add_argument("--bounds-file", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("dem/inkomati_dem.tif"))
    args = parser.parse_args()

    west, south, east, north = load_bounds(args.bounds_file)
    args.output.parent.mkdir(parents=True, exist_ok=True)

    for cli in ("eio", "elevation"):
        if shutil.which(cli):
            cmd = [cli, "clip", "-o", str(args.output), "--bounds", f"{west}", f"{south}", f"{east}", f"{north}"]
            break
    else:
        raise SystemExit("Install elevation CLI: pip install elevation (provides eio)")
    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)

    size_mb = args.output.stat().st_size / (1024 * 1024)
    print(f"Saved {args.output} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
