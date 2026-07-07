# Offline workflow — Lengau has no internet

When the cluster cannot reach the internet, prepare everything on your **PC** (or DTN when available), then **SCP to Lengau** and **push to GitHub** from your PC.

## What needs internet (do locally)

| Item | Local action | Upload to Lengau |
|------|--------------|------------------|
| **This repo / scripts** | `git push` from PC | `scp -r tlakale-case` to lustre |
| **GIS preprocessor** | Bundled under `gis/wrf_hydro_gis_preprocessor/` | Include in scp (no `git clone` on cluster) |
| **ERA5 GRIB** | CDS / Copernicus download on PC | `scp` to `era5_grib/` |
| **DEM GeoTIFF** | Download MERIT/Copernicus DEM for domain bbox | `scp` to `dem/inkomati_dem.tif` |
| **Conda GIS env** | Optional: build on PC or use Lengau modules + pip offline wheelhouse | See `setup_gis_env.sh` |

## What runs on Lengau only (no internet)

- `geogrid`, `ungrib`, `metgrid`, `real.exe`, `wrf.exe` (use `/home/apps` installs + lustre data)
- PBS jobs
- `run_gis_preproc.sh` **after** GIS tool + DEM are uploaded

---

## Deploy from Windows PC to tmogebisa lustre

From PowerShell (replace paths if needed):

```powershell
# 1. Push code to GitHub (from your PC)
cd C:\Users\MthethoSovara\tiny-media-analysis\wrf-lengau
git add examples/tlakale-case/
git commit -m "Update tlakale-case"
git push origin main

# 2. Upload package to Lengau (tmogebisa can then own her copy)
scp -r examples/tlakale-case msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/

# 3. Upload DEM when ready (large file)
scp dem/inkomati_dem.tif msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/dem/

# 4. Upload ERA5 for test month / years
scp era5_grib/ERA5_2010_*.grib msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/era5_grib/
```

On **login2**, tmogebisa should take ownership of her copy:

```bash
cp -r ~/lustre/WRF-Hydro_Coupled/tlakale-case ~/lustre/WRF-Hydro_Coupled/examples/
chmod -R u+rwX ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case
chmod +x ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case/scripts/*.sh
perl -pi -e 's/\r\n/\n/g' ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case/scripts/*.sh
```

---

## DEM download (local PC)

Domain centre ~ **25.5°S, 31.5°E**; d01 is ~2200 km × 1900 km (15 km grid). Use bounds from `geo_em.d01.nc` on Lengau:

```bash
module load chpc/python/anaconda/3-2024.10.1
python scripts/geo_em_bounds.py cases/my_hydro_run/DOMAIN/geo_em.d01.nc
```

Download **hydrologically conditioned** DEM (metres), e.g.:

- [MERIT Hydro DEM](http://hydro.iis.u-tokyo.ac.jp/~yamadai/MERIT_DEM/)
- [Copernicus DEM 30m](https://spacedata.copernicus.eu/)

Save as `inkomati_dem.tif` and SCP to `WRF-Hydro_Coupled/dem/`.

---

## GIS preprocessor on Lengau (offline)

The repo includes `gis/wrf_hydro_gis_preprocessor/` — no cluster `git clone` needed.

On Lengau login (uses existing Anaconda module):

```bash
cd ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case
bash scripts/setup_gis_env.sh   # creates conda env if not present; uses bundled gis/
source gis/activate_gis_env.sh
```

If conda create fails offline, ask CHPC support or create the env once on DTN and export:

```bash
conda env export -n wrfh_gis_env > wrfh_gis_env.yml   # on machine with internet
# transfer yml + use conda env create -f wrfh_gis_env.yml on Lengau
```

Then:

```bash
qsub -v DEM_PATH=/home/tmogebisa/lustre/WRF-Hydro_Coupled/dem/inkomati_dem.tif scripts/run_gis_preproc.pbs
```

---

## Current status checklist (tmogebisa)

| Step | Status |
|------|--------|
| WRF/Hydro tables in `my_hydro_run` | Done |
| `hydro.namelist` coupled (`sys_cpl=2`) | Done |
| `geo_em.d01/d02.nc` in DOMAIN | Done |
| Routing files (Fulldom, Route_Link, …) | **Pending DEM + GIS job** |
| Phase 1 `namelist.input` applied | **Run `apply_namelists.sh`** |
| ERA5 GRIB on lustre | **Download locally + scp** |
| GIS tool on lustre | **scp bundled `gis/` folder** |
