# Tlakale case — Inkomati River catchment WRF-Hydro Phase 1

Coupled WRF-Hydro namelists and PBS scripts for the **Inkomati basin** water-balance study (1980–2010), designed for **CHPC Lengau** with module `chpc/earth/wrf-lengau-gcc-hydro`.

## Domain summary

| Domain | Resolution | Grid | Role |
|--------|------------|------|------|
| d01 | 15 km | 150 × 130 | Regional (southern Africa / Mozambique border) |
| d02 | 5 km (÷3 nest) | 220 × 214 | Inkomati catchment focus |

Map centre: **25.5°S, 31.5°E** (Lambert conformal).

## Files

```
examples/tlakale-case/
  config.env                          # paths, project, LSM choice
  namelists/
    namelist.input.test               # Jan 2010 workflow test
    namelist.input.year               # one calendar year (__YEAR__ placeholder)
    namelist.wps.test                 # WPS for Jan 2010
    namelist.wps.year                 # WPS for one year
    namelist.hrldas.noahmp            # NoahMP physics (recommended)
    namelist.hrldas.noah              # Noah physics (alternative)
  scripts/
    setup_case.sh                     # create dirs, link tables, patch hydro.namelist
    apply_namelists.sh                # install test or year namelists
    patch_hydro_namelist.sh           # sys_cpl=2, water-balance outputs
    link_met_em.sh                    # WPS → WRF met_em link
    run_wps.pbs
    run_real.pbs
    run_wrf.pbs
    run_phase1_years.sh               # 1980–2010 year loop
```

## Quick start on Lengau

### 1. Edit configuration

```bash
cd ~/wrf-hydro-coupled-lengau/examples/tlakale-case
nano config.env
```

Set at minimum:

- `PBS_PROJECT` — your CHPC project code
- `GEOG_DATA_PATH` — path to WPS static geography (confirm on Lengau)
- `WPS_DIR` — your compiled WPS install
- `CASE_ROOT` — where case data will live (default `~/cases/tlakale_case`)

### 2. Create case directory

```bash
bash scripts/setup_case.sh
```

This creates `~/cases/tlakale_case/wrf` and `~/cases/tlakale_case/wps`, links WRF/Hydro tables, and patches `hydro.namelist` for **coupled** mode (`sys_cpl = 2`).

### 3. Prepare routing GIS (required before hydro routing works)

Place preprocessed WRF-Hydro domain files under `CASE_DIR/DOMAIN/`:

- `geo_em.d01.nc` (from WPS `geogrid`)
- `Fulldom_hires.nc`, `hydro2dtbl.nc`, `Route_Link.nc`, etc.

See WRF-Hydro GIS pre-processing documentation. Without these, the atmospheric run may start but routing will fail.

### 4. Test run (January 2010)

```bash
# Apply namelists
SIM_MODE=test bash scripts/apply_namelists.sh

# WPS (after ERA5 GRIB in ERA5_GRIB_DIR)
qsub scripts/run_wps.pbs

# Link met_em and run real + wrf
bash scripts/link_met_em.sh
qsub scripts/run_real.pbs
qsub -v SIM_MODE=test scripts/run_wrf.pbs
```

### 5. Phase 1 production (1980–2010)

Run **one year per job** with restarts — do not attempt a single 30-year simulation.

```bash
# Example: first year
SIM_MODE=year RUN_YEAR=1980 RESTART=false bash scripts/apply_namelists.sh
# WPS for 1980 ERA5, then real, then:
qsub -v SIM_MODE=year,RUN_YEAR=1980,RESTART=false scripts/run_wrf.pbs

# Subsequent years (after copying restart/wrfinput from previous year end)
qsub -v SIM_MODE=year,RUN_YEAR=1981,RESTART=true scripts/run_wrf.pbs

# Or preview all submit commands:
bash scripts/run_phase1_years.sh
bash scripts/run_phase1_years.sh submit
```

## Namelist highlights

### `namelist.input`

- **Test:** 2010-01-01 → 2010-01-31, hourly history (`interval_seconds = 3600`)
- **Year:** `__YEAR__`-01-01 → `__YEAR__`-12-31
- **LSM:** NoahMP (`sf_surface_physics = 5`) — switch to Noah (`2`) via `LSM_OPTION=noah` in `apply_namelists.sh`
- **Timestep:** 60 s (safer for 5 km nest)
- **Nested boundaries:** `specified = .true., .false.` and `nested = .false., .true.`
- **`&hydro`:** routing enabled; closing `/` included

### `hydro.namelist`

Copied from the install and patched by `patch_hydro_namelist.sh`:

- `sys_cpl = 2` (coupled to WRF, not offline)
- `SPLIT_OUTPUT_COUNT = 1` (required for coupled)
- `LSMOUT_DOMAIN = 1`, `RTOUT_DOMAIN = 1`, `CHRTOUT_DOMAIN = 1` for water-balance fluxes

### `namelist.wps`

Dates and grid must match `namelist.input`. `geog_data_path` is substituted from `GEOG_DATA_PATH` in `config.env`.

### `namelist.hrldas`

Physics options for NoahMP; dates are placeholders in coupled mode (WRF drives forcing). Keep `NOAH_TIMESTEP = 3600` aligned with WRF history interval.

## Workflow diagram

```
ERA5 GRIB → WPS (geogrid/ungrib/metgrid) → met_em.*
                                              ↓
                                         real.exe → wrfinput, wrfbdy
                                              ↓
                    DOMAIN/* (GIS) + hydro.namelist + namelist.hrldas
                                              ↓
                                         wrf.exe (coupled WRF-Hydro)
                                              ↓
                              wrfout_* + CHRTOUT/RTOUT/LSMOUT (water balance)
```

## Storage note

30 years at 5 km with hourly output is very large. Plan post-processing to daily means and subset variables after each year completes.

## Related documentation

- [USER_GUIDE.md](../../docs/USER_GUIDE.md) — coupled build on Lengau
- [run_wrf_coupled.pbs](../run_wrf_coupled.pbs) — generic coupled PBS template
