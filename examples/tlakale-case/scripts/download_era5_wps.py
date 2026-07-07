#!/usr/bin/env python3
"""
Download ERA5 GRIB files for WRF WPS (ungrib) — run on PC with internet.

Requires: pip install cdsapi
Credentials: ~/.cdsapirc (see https://cds.climate.copernicus.eu/)

Usage:
  python download_era5_wps.py --year 2010 --area -35 18 -16 45
  python download_era5_wps.py --year 2010 --bounds-file domain_bounds.env

Output: era5_grib/ERA5_YYYY_pressure.grib, ERA5_YYYY_surface.grib
Upload: scp era5_grib/ERA5_2010_*.grib msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/era5_grib/
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path

try:
    import cdsapi
except ImportError as exc:
    raise SystemExit("Install cdsapi: pip install cdsapi") from exc


PRESSURE_VARS = [
    "geopotential",
    "temperature",
    "u_component_of_wind",
    "v_component_of_wind",
    "relative_humidity",
]

SURFACE_VARS = [
    "2m_temperature",
    "2m_dewpoint_temperature",
    "10m_u_component_of_wind",
    "10m_v_component_of_wind",
    "surface_pressure",
    "mean_sea_level_pressure",
    "skin_temperature",
    "soil_temperature_level_1",
    "soil_temperature_level_2",
    "soil_temperature_level_3",
    "soil_temperature_level_4",
]

PRESSURE_LEVELS = [
    "1000", "975", "950", "925", "900", "875", "850", "825", "800", "775",
    "750", "700", "650", "600", "550", "500", "450", "400", "350", "300",
    "250", "200", "150", "100", "70", "50",
]

MONTHS = [f"{m:02d}" for m in range(1, 13)]
DAYS = [f"{d:02d}" for d in range(1, 32)]
TIMES = [f"{h:02d}:00" for h in range(0, 24, 6)]


def load_bounds(bounds_file: Path) -> list[float]:
    vals: dict[str, float] = {}
    for line in bounds_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        vals[key.strip()] = float(value.strip())
    north = vals["lat_max"]
    south = vals["lat_min"]
    west = vals["lon_min"]
    east = vals["lon_max"]
    pad = 2.0
    return [north + pad, west - pad, south - pad, east + pad]


def main() -> None:
    parser = argparse.ArgumentParser(description="Download ERA5 for WRF WPS")
    parser.add_argument("--year", type=int, required=True)
    parser.add_argument(
        "--area",
        type=float,
        nargs=4,
        metavar=("N", "W", "S", "E"),
        help="CDS area: north west south east (degrees)",
    )
    parser.add_argument(
        "--bounds-file",
        type=Path,
        help="File with lat_min/lat_max/lon_min/lon_max from get_domain_bounds.sh",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("era5_grib"),
    )
    parser.add_argument("--month-start", type=int, default=1)
    parser.add_argument("--month-end", type=int, default=12)
    args = parser.parse_args()

    if args.bounds_file:
        area = load_bounds(args.bounds_file)
    elif args.area:
        area = list(args.area)
    else:
        # Inkomati d01 approximate fallback (run get_domain_bounds.sh for exact)
        area = [-16.0, 18.0, -35.0, 45.0]

    months = [f"{m:02d}" for m in range(args.month_start, args.month_end + 1)]
    out_dir = args.output_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    year = str(args.year)
    client = cdsapi.Client()

    pressure_out = out_dir / f"ERA5_{year}_pressure.grib"
    surface_out = out_dir / f"ERA5_{year}_surface.grib"

    print(f"Area (N W S E): {area}")
    print(f"Months: {months[0]}–{months[-1]}")

    if not pressure_out.exists():
        print(f"Downloading pressure levels -> {pressure_out}")
        client.retrieve(
            "reanalysis-era5-pressure-levels",
            {
                "product_type": "reanalysis",
                "variable": PRESSURE_VARS,
                "pressure_level": PRESSURE_LEVELS,
                "year": year,
                "month": months,
                "day": DAYS,
                "time": TIMES,
                "area": area,
                "format": "grib",
            },
            str(pressure_out),
        )
    else:
        print(f"Skip existing {pressure_out}")

    if not surface_out.exists():
        print(f"Downloading surface -> {surface_out}")
        client.retrieve(
            "reanalysis-era5-single-levels",
            {
                "product_type": "reanalysis",
                "variable": SURFACE_VARS,
                "year": year,
                "month": months,
                "day": DAYS,
                "time": TIMES,
                "area": area,
                "format": "grib",
            },
            str(surface_out),
        )
    else:
        print(f"Skip existing {surface_out}")

    print("Done. Upload with:")
    print(
        f"  scp {out_dir}/ERA5_{year}_*.grib "
        "msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/era5_grib/"
    )


if __name__ == "__main__":
    main()
