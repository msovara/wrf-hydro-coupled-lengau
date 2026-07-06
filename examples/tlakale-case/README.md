# Tlakale case — Inkomati River catchment WRF-Hydro Phase 1

Coupled WRF-Hydro namelists and PBS scripts for the **Inkomati basin** water-balance study (**1980–2010**), on **CHPC Lengau** with module `chpc/earth/wrf-lengau-gcc-hydro`.

## Phase 1 strategy

| Step | Period | Purpose |
|------|--------|---------|
| **Test** | Jan 2010 | Verify WPS → real → wrf workflow |
| **Production** | 1980–2010 | One calendar year per job, daily restarts, chain years |

Do **not** run 30 years in a single job.

## Domain

| Domain | Resolution | Grid | Role |
|--------|------------|------|------|
| d01 | 15 km | 150 × 130 | Regional |
| d02 | 5 km (÷3) | 220 × 214 | Inkomati catchment |

Centre: **25.5°S, 31.5°E** · LSM: **NoahMP** · History: **hourly** · WRF timestep: **60 s**

## Layout on Lengau (tmogebisa)

```
/home/tmogebisa/lustre/WRF-Hydro_Coupled/
  examples/tlakale-case/          ← namelists + scripts (this package)
  cases/my_hydro_run/             ← WRF case (namelist.input, hydro.namelist, DOMAIN/)
  cases/wps/                      ← WPS namelist.wps, met_em output
  era5_grib/                      ← ERA5 forcing per year
  restarts/                       ← archived wrfrst per year (1980, 1981, …)
```

## Files

```
tlakale-case/
  config.env                      Phase 1 paths and year range (1980–2010)
  namelists/
    namelist.input.test           Jan 2010 test
    namelist.input.year           one calendar year template
    namelist.wps.test / .year
    namelist.hrldas.noahmp
  scripts/
    apply_namelists.sh            deploy namelists + patch hydro
    patch_hydro_namelist.sh       sys_cpl=2, hourly water-balance outputs
    prepare_year_restart.sh       link previous year wrfrst
    archive_year_restart.sh       save end-of-year restarts
    link_met_em.sh
    run_wps.pbs / run_real.pbs / run_wrf.pbs / run_wrf_test.pbs
    run_phase1_years.sh           submit 1980–2010 chain
```

## Workflow

### 1. Configure

Paths are preset in `config.env` for Lengau:

| Variable | Value |
|----------|-------|
| `PBS_PROJECT` | `ERTH0859` |
| `WPS_DIR` | `/home/apps/chpc/earth/WRF-4.7.1-gcc/bin` |
| `GEOG_DATA_PATH` | `/home/apps/chpc/earth/CROCCO_Workshop/geog/WPS_GEOG` |
| `CASE_ROOT` | `/home/tmogebisa/lustre/WRF-Hydro_Coupled/cases/my_hydro_run` |

## CHPC Lengau queues (ERTH0859)

| Stage | Queue | Cores | Walltime | Script |
|-------|-------|-------|----------|--------|
| WPS | **serial** | 16 (max 23) | 8 h | `run_wps.pbs` |
| real.exe | **normal** | 48 (min 25) | 8 h | `run_real.pbs` |
| wrf.exe (test/production) | **normal** | 48 | 48 h max | `run_wrf.pbs` |
| Smoke test only | **test** | 24 | 3 h max | `run_wrf_test.pbs` |

**Important:** the **normal** queue allows at most **48 h** per job. A full calendar year may not finish in one job — use `restart=.true.` and chain jobs, or split into seasons (e.g. Jan–Jun / Jul–Dec) in the namelist.

Do **not** submit WPS to **normal** (minimum 25 cores per job).

```bash
cd /home/tmogebisa/lustre/WRF-Hydro_Coupled/tlakale-case
nano config.env   # only if paths or queue need changing
```

### 2. Test (January 2010)

```bash
SIM_MODE=test bash scripts/apply_namelists.sh
bash scripts/patch_hydro_namelist.sh \
  /home/tmogebisa/lustre/WRF-Hydro_Coupled/cases/my_hydro_run/hydro.namelist

qsub -v SIM_MODE=test scripts/run_wps.pbs
qsub -v SIM_MODE=test scripts/run_real.pbs
qsub -v SIM_MODE=test scripts/run_wrf.pbs
```

### 3. Phase 1 production (1980–2010)

One year at a time. Place ERA5 for each year in `era5_grib/ERA5_1980_*.grib`, etc.

**First year (cold start):**
```bash
qsub -v SIM_MODE=year,RUN_YEAR=1980,RESTART=false scripts/run_wps.pbs
# after WPS completes:
qsub -v SIM_MODE=year,RUN_YEAR=1980,RESTART=false scripts/run_real.pbs
qsub -v SIM_MODE=year,RUN_YEAR=1980,RESTART=false scripts/run_wrf.pbs
```

**Subsequent years (restart from previous):**
```bash
qsub -v SIM_MODE=year,RUN_YEAR=1981,RESTART=true,PREV_YEAR=1980 scripts/run_wrf.pbs
```

Or submit the full chain (WRF only, assumes WPS/real already done or chained separately):
```bash
bash scripts/run_phase1_years.sh submit
bash scripts/run_phase1_years.sh submit-all   # WPS+real+WRF per year
```

Restarts are archived automatically at end of each `run_wrf.pbs` year job under `restarts/YYYY/`.

### 4. Routing GIS (required)

**Step A — geo_em from geogrid (no ERA5 needed):**
```bash
qsub scripts/run_geogrid.pbs
# creates DOMAIN/geo_em.d01.nc and geo_em.d02.nc
```

**Step B — install GIS preprocessor (DTN or any host with internet):**
```bash
bash scripts/setup_gis_env.sh
source gis/activate_gis_env.sh
```

**Step C — obtain a hydrologically conditioned DEM** (metres) covering the domain. After geogrid:
```bash
python scripts/geo_em_bounds.py cases/my_hydro_run/DOMAIN/geo_em.d01.nc
```
Download MERIT/Copernicus DEM for that bbox (e.g. from [MERIT Hydro](http://hydro.iis.u-tokyo.ac.jp/~yamadai/MERIT_DEM/) or OpenTopography), place as `dem/inkomati_dem.tif`.

**Step D — build routing stack:**
```bash
qsub -v DEM_PATH=/home/tmogebisa/lustre/WRF-Hydro_Coupled/dem/inkomati_dem.tif scripts/run_gis_preproc.pbs
```

This produces in `DOMAIN/`:
`Fulldom_hires.nc`, `hydro2dtbl.nc`, `Route_Link.nc`, `GEOGRID_LDASOUT_Spatial_Metadata.nc`, `GWBASINS.nc`, `GWBUCKPARM.nc`, `LAKEPARM.nc` (as applicable).

| Script | Purpose |
|--------|---------|
| `run_geogrid.sh` / `.pbs` | WPS geogrid → `geo_em.d0*.nc` |
| `setup_gis_env.sh` | Clone NCAR GIS tool + conda env |
| `run_gis_preproc.sh` / `.pbs` | DEM + geo_em → routing files |

## Phase 1 namelist settings

| Setting | Value | File |
|---------|-------|------|
| Analysis period | 1980–2010 | `config.env` |
| Output interval | 3600 s (hourly) | `namelist.input.*` |
| WRF restart interval | 1440 min (daily) | `namelist.input.year` |
| Hydro output | 60 min | `hydro.namelist` (patched) |
| Coupling | `sys_cpl = 2` | `hydro.namelist` (patched) |
| LSM fluxes | `LSMOUT_DOMAIN = 1` | `hydro.namelist` (patched) |

## Storage

Hourly 5 km output for 31 years is very large. Archive daily means after each year in post-processing.
