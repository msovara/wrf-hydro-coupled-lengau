#!/usr/bin/env python3
"""
Download Copernicus DEM 30m via OpenTopography API — run on PC with internet.

Requires: pip install requests rasterio

Get a free API key: https://opentopography.org/developers
  set OPENTOPO_API_KEY=your_key

Usage:
  python download_dem_opentopo.py --bounds-file domain_bounds.env --output dem/inkomati_dem.tif

Or pass bounds directly (south north west east in WGS84):
  python download_dem_opentopo.py --south -35 --north -16 --west 18 --east 45

Upload:
  scp dem/inkomati_dem.tif msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/dem/
"""
from __future__ import annotations

import argparse
import os
import zipfile
from io import BytesIO
from pathlib import Path

try:
    import requests
except ImportError as exc:
    raise SystemExit("Install requests: pip install requests") from exc


def load_bounds(bounds_file: Path) -> tuple[float, float, float, float]:
    vals: dict[str, float] = {}
    for line in bounds_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        vals[key.strip()] = float(value.strip())
    pad = 0.25
    south = vals["lat_min"] - pad
    north = vals["lat_max"] + pad
    west = vals["lon_min"] - pad
    east = vals["lon_max"] + pad
    return south, north, west, east


def main() -> None:
    parser = argparse.ArgumentParser(description="Download Copernicus DEM 30m")
    parser.add_argument("--bounds-file", type=Path)
    parser.add_argument("--south", type=float)
    parser.add_argument("--north", type=float)
    parser.add_argument("--west", type=float)
    parser.add_argument("--east", type=float)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("dem/inkomati_dem.tif"),
    )
    args = parser.parse_args()

    api_key = os.environ.get("OPENTOPO_API_KEY")
    if not api_key:
        raise SystemExit(
            "Set OPENTOPO_API_KEY (free key from https://opentopography.org/developers)"
        )

    if args.bounds_file:
        south, north, west, east = load_bounds(args.bounds_file)
    elif None not in (args.south, args.north, args.west, args.east):
        south, north, west, east = args.south, args.north, args.west, args.east
    else:
        raise SystemExit("Provide --bounds-file or --south/--north/--west/--east")

    args.output.parent.mkdir(parents=True, exist_ok=True)

    url = "https://portal.opentopography.org/API/globaldem"
    params = {
        "demtype": "COP30",
        "south": south,
        "north": north,
        "west": west,
        "east": east,
        "outputFormat": "GTiff",
        "API_Key": api_key,
    }

    print(f"Requesting Copernicus DEM 30m: S={south:.3f} N={north:.3f} W={west:.3f} E={east:.3f}")
    resp = requests.get(url, params=params, timeout=600)
    resp.raise_for_status()

    content_type = resp.headers.get("Content-Type", "")
    if "zip" in content_type or resp.content[:2] == b"PK":
        with zipfile.ZipFile(BytesIO(resp.content)) as zf:
            tifs = [n for n in zf.namelist() if n.lower().endswith((".tif", ".tiff"))]
            if not tifs:
                raise SystemExit("ZIP response contained no GeoTIFF")
            data = zf.read(tifs[0])
        args.output.write_bytes(data)
    else:
        args.output.write_bytes(resp.content)

    size_mb = args.output.stat().st_size / (1024 * 1024)
    print(f"Saved {args.output} ({size_mb:.1f} MB)")
    print("Upload with:")
    print(
        f"  scp {args.output} "
        "msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/dem/"
    )


if __name__ == "__main__":
    main()
