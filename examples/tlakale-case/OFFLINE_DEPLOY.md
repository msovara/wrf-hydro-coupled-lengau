# Offline workflow — Lengau has no internet

When the cluster cannot reach the internet, prepare everything on your **PC**, then **SCP to Lengau**. Push script updates to GitHub from your PC only.

---

## What needs internet (do on PC)

| Item | Local action | Upload to Lengau |
|------|--------------|------------------|
| **Scripts / namelists** | `git pull` / edit / `git push` | `scp -r examples/tlakale-case` |
| **GIS preprocessor** | Bundled under `gis/wrf_hydro_gis_preprocessor/` | Include in scp |
| **Routing DOMAIN** | `run_gis_preproc_local.py` (recommended) | `scp DOMAIN/*.nc` to `cases/my_hydro_run/DOMAIN/` |
| **ERA5 GRIB** | `download_era5_wps.py` + CDS | `scp` to `era5_grib/` |
| **DEM GeoTIFF** | `download_dem_opentopo.py` or similar | `scp` to `dem/inkomati_dem.tif` |
| **Conda GIS env** | `conda create -n wrfh_gis_env …` on PC | Not needed on Lengau if GIS run locally |

---

## What runs on Lengau only

- `geogrid`, `ungrib`, `metgrid`, `real.exe`, `wrf.exe` (CHPC modules + lustre data)
- PBS jobs
- Optional: `run_gis_preproc.pbs` if offline conda env exists (usually fails — use PC instead)

---

## Deploy from Windows PC

```powershell
cd C:\Users\MthethoSovara\tiny-media-analysis\wrf-lengau

# Push to GitHub
git add examples/tlakale-case/
git commit -m "Update tlakale-case"
git push origin main

# Upload package
scp -r examples/tlakale-case msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/examples/

# Large data (separate)
scp dem/inkomati_dem.tif msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/dem/
scp era5_grib/ERA5_2010_*.grib msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/era5_grib/
scp DOMAIN/Fulldom_hires.nc DOMAIN/Route_Link.nc ... msovara@lengau.chpc.ac.za:.../cases/my_hydro_run/DOMAIN/
```

**On Lengau after scp:**

```bash
perl -pi -e 's/\r\n/\n/g; s/\r/\n/g' ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case/scripts/*.sh
perl -pi -e 's/\r\n/\n/g; s/\r/\n/g' ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case/scripts/*.pbs
chmod +x ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case/scripts/*.sh
```

---

## Domain bounds (for PC downloads)

From `geo_em.d01.nc` on Lengau:

```bash
bash scripts/get_domain_bounds.sh
```

Reference values (Jul 2026) are in `domain_bounds.env`:

```
lat_min=-34.1596  lat_max=-16.5047
lon_min=19.4645   lon_max=43.5355
```

---

## ERA5 download (PC)

Requires `~/.cdsapirc` (Copernicus CDS) and `pip install cdsapi`.

```powershell
cd examples/tlakale-case
python scripts/download_era5_wps.py --year 2010 --bounds-file domain_bounds.env `
    --month-start 1 --month-end 1 --output-dir era5_grib
```

For a full calendar year, use `--month-start 1 --month-end 12` and set WPS `end_date` to `(year+1)-01-01_00:00:00` or ensure the last 6-hourly time exists in GRIB.

**Never use `_24:00:00` in WPS dates.**

---

## DEM download (PC)

**Recommended:** OpenTopography (one merged GeoTIFF, free API key):

```powershell
$env:OPENTOPO_API_KEY = "your_key"
python scripts/download_dem_opentopo.py --bounds-file domain_bounds.env
```

**Interim testing only:** export from geogrid orography:

```powershell
python scripts/export_dem_from_geoem.py geo_em.d01.nc --output dem/inkomati_dem.tif
```

Production runs should use a hydrologically conditioned DEM (MERIT, Copernicus 30 m).

---

## GIS routing stack (PC — recommended)

Lengau login nodes cannot reach conda-forge. Build on PC:

```powershell
conda create -n wrfh_gis_env -c conda-forge python=3.10 gdal netCDF4 numpy pyproj whitebox packaging shapely
conda activate wrfh_gis_env

scp msovara@lengau.chpc.ac.za:.../DOMAIN/geo_em.d01.nc .

python scripts/run_gis_preproc_local.py --geo-em geo_em.d01.nc --dem dem/inkomati_dem.tif
```

Upload outputs:

```powershell
scp DOMAIN/Fulldom_hires.nc DOMAIN/Route_Link.nc `
    DOMAIN/GEOGRID_LDASOUT_Spatial_Metadata.nc DOMAIN/GWBASINS.nc DOMAIN/GWBUCKPARM.nc `
    msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/cases/my_hydro_run/DOMAIN/
```

---

## Progress checklist

| Step | Status (Jul 2026) |
|------|-------------------|
| WRF/Hydro tables in `my_hydro_run` | Done |
| `hydro.namelist` coupled (`sys_cpl=2`) | Done |
| `geo_em.d01/d02.nc` | Done |
| Routing DOMAIN files | Done (PC build + scp) |
| ERA5 Jan 2010 on lustre | Done |
| WPS / metgrid Jan 2010 | Done |
| `real.exe` | Run / verify |
| Coupled WRF test | Pending |

See **[README.md](README.md)** for the full user guide and troubleshooting.
