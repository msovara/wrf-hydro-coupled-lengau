# WRF-Hydro Installation on Lengau

Two build modes are supported on Lengau:

| Mode | Use when | Output | Toolchain |
|------|----------|--------|-----------|
| **Standalone** | Offline land/hydrology (NoahMP + routing) | `wrf_hydro.exe` | Intel oneAPI 2021.3 |
| **Coupled** | WRF atmosphere + routing in one `wrf.exe` | `wrf.exe` | Intel or GCC |

The old `setWRF-HYDRO` environment (Parallel Studio 2017) is **obsolete** on
Lengau. Use the scripts in this repo.

## Critical: WRF 4.7+ requires `phys/physics_mmm`

WRF v4.7+ pulls MMM physics from GitHub via `manage_externals`. **`./clean -a`
deletes `phys/physics_mmm`**. Failed Intel/hydro builds on Lengau were traced to
this directory being missing after clean rebuilds.

**Before any coupled or plain WRF 4.7.1 build:**

1. On the **DTN** (GitHub access), run:

```bash
export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-hydro   # or your install dir
bash checkout_wrf_externals_dtn.sh
```

2. Or copy from the working GCC tree (login node):

```bash
rsync -a /home/apps/chpc/earth/WRF-4.7.1-gcc/build/WRF/phys/physics_mmm \
  /home/apps/chpc/earth/WRF-4.7.1-hydro/build/WRF/phys/
```

3. Submit PBS jobs with **`WRF_RUN_CLEAN=0`** (or leave unset — `install_wrf_lengau_clean.sh`
   auto-skips `./clean -a` when `phys/physics_mmm/.git` exists).

## Standalone WRF-Hydro (working)

Install: `/home/apps/chpc/earth/WRF-Hydro-5.3.0-standalone-intel2021.3/`

```bash
module load chpc/earth/wrf-hydro-standalone
source /home/apps/chpc/earth/WRF-Hydro-5.3.0-standalone-intel2021.3/setup_wrf_hydro.sh
```

Build script: `install_wrf_hydro_standalone_lengau.sh`

## Coupled WRF + WRF-Hydro

Use the unified clean build script with `WRF_HYDRO=1`:

```bash
export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-hydro
export TOOLCHAIN=intel          # or gcc
export WRF_HYDRO=1
export WRF_CONFIG_OPTION=66     # Intel Haswell/BDW on Lengau; use 34 for GCC
export WRF_RUN_CLEAN=0
bash install_wrf_lengau_clean.sh
```

### Validation builds (three PBS jobs)

`deploy_validation_builds.sh` stages source (with `physics_mmm` from the working GCC
tree) and submits:

| Job | Install dir | Purpose |
|-----|-------------|---------|
| Plain Intel | `WRF-4.7.1-plain-intel` | Validate Intel toolchain without hydro |
| Coupled Intel | `WRF-4.7.1-hydro` | WRF + hydro, Intel option 66 |
| Coupled GCC | `WRF-4.7.1-hydro-gcc` | WRF + hydro, GCC (known-good compiler) |

```bash
cd /home/apps/chpc/earth/wrf-lengau-scripts
bash deploy_validation_builds.sh
```

## Compile diagnostics

If `wrf.exe` is missing after compile:

```bash
bash diagnose_wrf_compile.sh /home/apps/chpc/earth/WRF-4.7.1-hydro/build/WRF
```

Checks:

- `phys/physics_mmm/.git` present
- `main/*.exe` built
- `libwrflib.a` unresolved symbols (e.g. `init_modules_em_`)
- Latest `compile_pass*.log` errors

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| No `wrf.exe`, undefined `init_modules_em_` | Incomplete archive / missing MMM physics | Restore `physics_mmm`, rebuild with `WRF_RUN_CLEAN=0` |
| `phys/physics_mmm` missing | Ran `./clean -a` without DTN checkout | `checkout_wrf_externals_dtn.sh` or rsync from GCC tree |
| Parallel compile races | `-j 4` on dependency-heavy targets | Use `install_wrf_lengau_clean.sh` (defaults to `-j 1`, 8 passes) |
| CRLF in PBS scripts | Windows SCP | Write PBS on cluster via heredoc; never `tr -d '\r'` |
| Old Parallel Studio paths | Retired `setWRF-HYDRO` | Use oneAPI 2021.3 scripts |

## References

- [WRF-Hydro documentation](https://wrf-hydro.readthedocs.io/)
- [WRF-Hydro GitHub releases](https://github.com/NCAR/wrf_hydro_nwm_public/releases)
