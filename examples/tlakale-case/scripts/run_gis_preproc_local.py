#!/usr/bin/env python3
"""
Run WRF-Hydro GIS routing stack locally (PC with internet + conda), then SCP DOMAIN files to Lengau.

Prerequisites on PC:
  conda create -n wrfh_gis_env -c conda-forge python=3.10 gdal netCDF4 numpy pyproj whitebox packaging shapely
  conda activate wrfh_gis_env
  pip install requests  # for download_dem_opentopo.py

Usage (from tlakale-case/):
  python scripts/download_dem_opentopo.py --bounds-file domain_bounds.env
  python scripts/run_gis_preproc_local.py --geo-em geo_em.d01.nc --dem dem/inkomati_dem.tif

Upload routing outputs:
  scp DOMAIN/*.nc msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/cases/my_hydro_run/DOMAIN/
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import zipfile
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Run Build_Routing_Stack locally")
    parser.add_argument("--geo-em", type=Path, required=True)
    parser.add_argument("--dem", type=Path, required=True)
    parser.add_argument("--regfact", type=int, default=4)
    parser.add_argument("--threshold", type=int, default=500)
    parser.add_argument("--routing", default="True")
    parser.add_argument(
        "--gis-tool-dir",
        type=Path,
        default=Path(__file__).resolve().parent.parent
        / "gis/wrf_hydro_gis_preprocessor/wrfhydro_gis",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("DOMAIN"),
    )
    args = parser.parse_args()

    for path in (args.geo_em, args.dem, args.gis_tool_dir / "Build_Routing_Stack.py"):
        if not path.exists():
            raise SystemExit(f"Missing: {path}")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    out_zip = args.output_dir / "routing_stack.zip"

    build = args.gis_tool_dir / "Build_Routing_Stack.py"
    cmd = [
        sys.executable,
        str(build),
        "-i",
        str(args.geo_em.resolve()),
        "-d",
        str(args.dem.resolve()),
        "-R",
        str(args.regfact),
        "-t",
        str(args.threshold),
        "-r",
        args.routing,
        "-o",
        str(out_zip.resolve()),
    ]
    print("Running:", " ".join(cmd))
    subprocess.run(cmd, cwd=args.gis_tool_dir, check=True)

    with zipfile.ZipFile(out_zip) as zf:
        zf.extractall(args.output_dir)
    print(f"Extracted routing files to {args.output_dir.resolve()}")
    for name in sorted(args.output_dir.glob("*")):
        if name.is_file():
            print(f"  {name.name} ({name.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
