# Tlakale case — Inkomati River catchment WRF-Hydro Phase 1

Coupled WRF-Hydro namelists and PBS scripts for the **Inkomati basin** water-balance study (**1980–2010**), on **CHPC Lengau** with module `chpc/earth/wrf-lengau-gcc-hydro`.

**Offline cluster:** Lengau login nodes have no internet. Download data and run GIS on your **PC**, then `scp` to lustre. See **[OFFLINE_DEPLOY.md](OFFLINE_DEPLOY.md)**.

---

## Phase 1 strategy

| Step | Period | Purpose |
|------|--------|---------|
| **Test** | Jan 2010 | Verify WPS → real → wrf workflow |
| **Production** | 1980–2010 | One calendar year per job, daily restarts, chain years |

Do **not** run 30 years in a single job.

---

## Domain

| Domain | Resolution | Grid | Role |
|--------|------------|------|------|
| d01 | 15 km | 150 × 130 | Regional |
| d02 | 5 km (÷3) | 220 × 214 | Inkomati catchment |

Centre: **25.5°S, 31.5°E** · LSM: **NoahMP** · History: **hourly** · WRF timestep: **60 s**

**d01 bounding box** (from geogrid, Jul 2026):

| | Value |
|--|-------|
| lat | −34.16 to −16.50 |
| lon | 19.46 to 43.54 |

Saved in `domain_bounds.env` for DEM/ERA5 downloads on your PC.

---

## Layout on Lengau (tmogebisa)

```
/home/tmogebisa/lustre/WRF-Hydro_Coupled/
  examples/tlakale-case/          ← namelists + scripts (this package)
  cases/my_hydro_run/             ← WRF case (namelist.input, hydro.namelist, DOMAIN/)
  cases/wps/                      ← WPS namelist.wps, met_em output
  era5_grib/                      ← ERA5 forcing per year
  dem/                            ← DEM GeoTIFF for GIS (optional on cluster)
  restarts/                       ← archived wrfrst per year (1980, 1981, …)
```

---

## Two parallel prep tracks (atmosphere vs routing)

| Track | What it builds | Required before |
|-------|----------------|-----------------|
| **WPS → real** | `met_em` → `wrfinput`, `wrfbdy` | Coupled `wrf.exe` |
| **Routing GIS** | `Fulldom_hires.nc`, `Route_Link.nc`, … | Coupled `wrf.exe` |

These are **independent** — run in either order or in parallel. Both must be complete before the coupled WRF-Hydro run.

---

## CHPC Lengau queues (ERTH0859)

| Stage | Queue | Cores | Walltime | Script |
|-------|-------|-------|----------|--------|
| geogrid / WPS | **serial** | 16 (max 23) | 8 h | `run_geogrid.pbs`, `run_wps.pbs` |
| real.exe | **normal** | 48 (min 25) | 8 h | `run_real.pbs` |
| wrf.exe (test/production) | **normal** | 48 | 48 h max | `run_wrf.pbs` |
| GIS preproc (if DEM on lustre) | **serial** | 8 | 12 h | `run_gis_preproc.pbs` |
| Smoke test only | **test** | 24 | 3 h max | `run_wrf_test.pbs` |

**Important:** Do **not** submit WPS to **normal** (minimum 25 cores per job). **normal** allows at most **48 h** per job — chain restarts for long years.

---

## Configuration (`config.env`)

| Variable | Value |
|----------|-------|
| `PBS_PROJECT` | `ERTH0859` |
| `WPS_DIR` | `/home/apps/chpc/earth/WRF-4.7.1-gcc/bin` |
| `WPS_ROOT` | `/home/apps/chpc/earth/WRF-4.7.1-gcc/build/WPS` |
| `GEOG_DATA_PATH` | `/home/apps/chpc/earth/CROCCO_Workshop/geog/WPS_GEOG` |
| `CASE_ROOT` | `/home/tmogebisa/lustre/WRF-Hydro_Coupled/cases/my_hydro_run` |
| `ERA5_GRIB_DIR` | `/home/tmogebisa/lustre/WRF-Hydro_Coupled/era5_grib` |
| `DEM_PATH` | `/home/tmogebisa/lustre/WRF-Hydro_Coupled/dem/inkomati_dem.tif` |

---

## Deploy from PC to Lengau

```powershell
# From repo root on Windows
cd wrf-lengau
scp -r examples/tlakale-case msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/examples/
```

Or use `deploy_to_lengau.ps1`.

**After every upload from Windows**, on Lengau:

```bash
perl -pi -e 's/\r\n/\n/g; s/\r/\n/g' scripts/*.sh scripts/*.pbs
chmod +x scripts/*.sh
```

CRLF line endings break `dirname` in scripts (`diname: command not found`) and prevent namelists from applying.

---

## Full workflow (recommended order)

### Step 1 — Geogrid (Lengau, no ERA5)

```bash
cd ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case
qsub scripts/run_geogrid.pbs
# → cases/my_hydro_run/DOMAIN/geo_em.d01.nc, geo_em.d02.nc
bash scripts/get_domain_bounds.sh   # print bbox for PC downloads
```

### Step 2 — Routing GIS (PC recommended; Lengau is offline for conda)

**On your PC** (internet + conda):

```powershell
cd examples/tlakale-case
conda create -n wrfh_gis_env -c conda-forge python=3.10 gdal netCDF4 numpy pyproj whitebox packaging shapely
conda activate wrfh_gis_env

# Download DEM (OpenTopography — free API key) or use export_dem_from_geoem.py for interim testing
$env:OPENTOPO_API_KEY = "your_key"
python scripts/download_dem_opentopo.py --bounds-file domain_bounds.env

# Or download ERA5 first, then scp geo_em from Lengau:
# scp msovara@lengau.chpc.ac.za:.../DOMAIN/geo_em.d01.nc .

python scripts/run_gis_preproc_local.py --geo-em geo_em.d01.nc --dem dem/inkomati_dem.tif

scp DOMAIN/Fulldom_hires.nc DOMAIN/Route_Link.nc DOMAIN/GEOGRID_LDASOUT_Spatial_Metadata.nc `
    DOMAIN/GWBASINS.nc DOMAIN/GWBUCKPARM.nc `
    msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/cases/my_hydro_run/DOMAIN/
```

Optional: `Create_SoilProperties_and_Hydro2D.py` for `hydro2dtbl.nc` (needs `pip install f90nml`).

**On Lengau** (only if conda GIS env exists and DEM is on lustre):

```bash
qsub -v DEM_PATH=/home/tmogebisa/lustre/WRF-Hydro_Coupled/dem/inkomati_dem.tif scripts/run_gis_preproc.pbs
```

### Step 3 — ERA5 download (PC)

```powershell
pip install cdsapi
# ~/.cdsapirc configured for Copernicus CDS

python scripts/download_era5_wps.py --year 2010 --bounds-file domain_bounds.env `
    --month-start 1 --month-end 1 --output-dir era5_grib

scp era5_grib/ERA5_2010_*.grib msovara@lengau.chpc.ac.za:/home/tmogebisa/lustre/WRF-Hydro_Coupled/era5_grib/
```

**ERA5 / WPS date rules:**

- WPS does **not** accept `_24:00:00` — use `2010-02-01_00:00:00` or the last 6-hourly slot you downloaded (e.g. `2010-01-31_18:00:00`).
- `namelist.wps` **end_date** must match times present in your GRIB files.
- Test config uses `2010-01-31_18:00:00` to match Jan-only ERA5 downloads.

### Step 4 — Test run (January 2010, Lengau)

```bash
cd ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case
SIM_MODE=test bash scripts/apply_namelists.sh

qsub -v SIM_MODE=test scripts/run_wps.pbs
# after WPS completes:
bash scripts/link_met_em.sh
qsub -v SIM_MODE=test scripts/run_real.pbs
# after real completes:
qsub -v SIM_MODE=test scripts/run_wrf.pbs
```

---

## Phase 1 production (1980–2010)

One year at a time. Place ERA5 for each year in `era5_grib/ERA5_YYYY_*.grib`.

**First year (cold start):**

```bash
qsub -v SIM_MODE=year,RUN_YEAR=1980,RESTART=false scripts/run_wps.pbs
qsub -v SIM_MODE=year,RUN_YEAR=1980,RESTART=false scripts/run_real.pbs
qsub -v SIM_MODE=year,RUN_YEAR=1980,RESTART=false scripts/run_wrf.pbs
```

**Subsequent years (restart):**

```bash
qsub -v SIM_MODE=year,RUN_YEAR=1981,RESTART=true,PREV_YEAR=1980 scripts/run_wrf.pbs
```

Or: `bash scripts/run_phase1_years.sh submit-all`

Year WPS templates use `end_date = 'YYYY+1-01-01_00:00:00'` (via `__NEXT_YEAR__` in `apply_namelists.sh`).

---

## Scripts reference

| Script | Purpose |
|--------|---------|
| `apply_namelists.sh` | Deploy test/year namelists + patch hydro |
| `patch_hydro_namelist.sh` | `sys_cpl=2`, hourly hydro outputs |
| `get_domain_bounds.sh` | Bbox from `geo_em.d01.nc` (uses `ncdump`, no Python netCDF4) |
| `download_era5_wps.py` | ERA5 GRIB for WPS (PC + CDS) |
| `download_dem_opentopo.py` | Copernicus 30 m DEM via OpenTopography (PC) |
| `export_dem_from_geoem.py` | Interim DEM from `HGT_M` (testing only) |
| `run_gis_preproc_local.py` | Build routing stack on PC |
| `run_geogrid.sh` / `.pbs` | geogrid → `geo_em.d0*.nc` |
| `run_wps.pbs` | geogrid + ungrib + metgrid (links `Vtable.ECMWF`) |
| `link_met_em.sh` | Link `met_em` into case dir |
| `run_real.pbs` | `real.exe` → `wrfinput`, `wrfbdy` |
| `run_wrf.pbs` / `run_wrf_test.pbs` | Coupled WRF-Hydro |
| `run_phase1_years.sh` | Submit 1980–2010 chain |
| `deploy_to_lengau.ps1` | Windows SCP helper |

---

## Routing DOMAIN files

After GIS preproc, `cases/my_hydro_run/DOMAIN/` should contain:

- `geo_em.d01.nc`, `geo_em.d02.nc` (geogrid)
- `Fulldom_hires.nc`, `Route_Link.nc`
- `GEOGRID_LDASOUT_Spatial_Metadata.nc`
- `GWBASINS.nc`, `GWBUCKPARM.nc`
- `hydro2dtbl.nc` (optional; from `Create_SoilProperties_and_Hydro2D.py`)

---

## Phase 1 namelist settings

| Setting | Value | File |
|---------|-------|------|
| Analysis period | 1980–2010 | `config.env` |
| Test period | Jan 2010 → 31 Jan 18:00 | `namelist.*.test` |
| Output interval | 3600 s (hourly) | `namelist.input.*` |
| WRF restart interval | 1440 min (daily) | `namelist.input.year` |
| Hydro output | 60 min | `hydro.namelist` (patched) |
| Coupling | `sys_cpl = 2` | `hydro.namelist` (patched) |

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `diname: command not found` | CRLF in scripts — run `perl -pi -e 's/\r\n/\n/g' scripts/*.sh` |
| `ERROR: Screwy NDATE: …_24:00:00` | Use `YYYY-MM-DD_00:00:00` or last 6-hourly time in GRIB |
| `Data not found: 2010-02-01_00` | Download Feb 1 ERA5 or set WPS end to last Jan time (`_18:00:00`) |
| `Could not open GEOGRID.TBL` | `run_geogrid.sh` creates `geogrid/GEOGRID.TBL` symlink |
| GIS conda fails on Lengau | Build routing stack on PC (`run_gis_preproc_local.py`) |
| `real` exits immediately | Fixed in `link_met_em.sh` (`head` + `set -e` pipefail) |
| numpy `int8` overflow in GIS | Patched in bundled `wrfhydro_functions.py` |

---

## Storage

Hourly 5 km output for 31 years is very large. Archive daily means after each year in post-processing.

---

## Progress checklist (Jul 2026)

| Step | Status |
|------|--------|
| WRF/Hydro tables in `my_hydro_run` | Done |
| `hydro.namelist` coupled (`sys_cpl=2`) | Done |
| `geo_em.d01/d02.nc` | Done |
| Routing files (Fulldom, Route_Link, …) | Done (built on PC, uploaded) |
| ERA5 Jan 2010 on lustre | Done |
| WPS metgrid Jan 2010 | Done |
| `real.exe` Jan 2010 | In progress / verify `wrfinput` |
| Coupled WRF test run | Pending after real |
