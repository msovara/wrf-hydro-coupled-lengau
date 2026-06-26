# WRF-Hydro Coupled Build — User Guide (CHPC Lengau)

This guide documents the **verified coupled WRF 4.7.1 + WRF-Hydro** installation on the CHPC Lengau cluster. In coupled mode, atmospheric and land/routing physics run together in a single `wrf.exe`.

## What is installed and working

| Item | Value |
|------|-------|
| **Build type** | Coupled WRF + WRF-Hydro |
| **WRF version** | 4.7.1 |
| **Compiler** | GNU gcc 8.3 + MPICH (configure option **34**) |
| **NetCDF module** | `chpc/earth/netcdf/4.7.4/gcc-8.3.0` |
| **Install path** | `/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc` |
| **Module name** | `chpc/earth/wrf-lengau-gcc-hydro` |
| **Executables** | `wrf.exe`, `real.exe`, `ndown.exe`, `tc.exe` |
| **Hydro compile flag** | `-DWRF_HYDRO` (confirmed in `configure.wrf`) |
| **Build date** | May 2026 — success on compile pass 1 (~25 min) |

**Standalone WRF-Hydro** (separate `wrf_hydro.exe`, Intel oneAPI) is also available on Lengau; see [Standalone vs coupled](#standalone-vs-coupled) below.

---

## Table of contents

1. [Architecture overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Quick start — use the existing install](#quick-start--use-the-existing-install)
4. [Full installation from scratch](#full-installation-from-scratch)
5. [Running coupled simulations](#running-coupled-simulations)
6. [PBS job workflow](#pbs-job-workflow)
7. [Verification checklist](#verification-checklist)
8. [Troubleshooting](#troubleshooting)
9. [Known limitations](#known-limitations)
10. [References](#references)

---

## Architecture overview

```
┌─────────────────────────────────────────────────────────────┐
│  DTN (dtn.chpc.ac.za) — internet access                     │
│  • git clone WRF v4.7.1                                     │
│  • checkout_externals → phys/physics_mmm (required for 4.7+)│
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│  Compute node (haswell_reg, internal queue)                 │
│  • configure with WRF_HYDRO=1                               │
│  • compile -j 1 em_real                                       │
│  • wrf.exe with hydro routing compiled in                   │
└─────────────────────────────────────────────────────────────┘
```

Coupled mode means you do **not** run a separate `wrf_hydro.exe`. Instead, `wrf.exe` calls the hydro routing layer when hydro namelists and tables are present.

---

## Prerequisites

### Access and resources

- CHPC Lengau account with `chpc_staff` group (for `internal` queue during install)
- SSH to `lengau.chpc.ac.za` and `dtn.chpc.ac.za`
- ~15 GB disk under `/home/apps/chpc/earth/` (or your install path)
- PBS job with **≥ 4 hours walltime** for compile (10 hours recommended)

### Software (loaded automatically by install script)

| Component | Module / path |
|-----------|---------------|
| GCC + MPICH | via `chpc/earth/netcdf/4.7.4/gcc-8.3.0` |
| NetCDF | `chpc/earth/netcdf/4.7.4/gcc-8.3.0` |
| Python 3 | `chpc/python/anaconda/3-2024.10.1` (for externals checkout on DTN) |
| Git ≥ 2.x | `chpc/git/2.41.0` on DTN |

### Critical requirement: `phys/physics_mmm`

WRF 4.7+ requires the MMM physics external checkout. **`./clean -a` deletes this directory.** Always run `checkout_wrf_externals_dtn.sh` on the DTN before building, and use `WRF_RUN_CLEAN=0` when rebuilding.

---

## Quick start — use the existing install

If the cluster install is already present:

```bash
# Login to Lengau
ssh user@lengau.chpc.ac.za

# Load coupled WRF-Hydro (GCC)
module load chpc/earth/wrf-lengau-gcc-hydro

# Confirm environment
echo $WRF_ROOT
which wrf.exe real.exe

# Verify hydro was compiled in
grep WRF_HYDRO $WRF_ROOT/share/wrf/configure.wrf
# Should show: ENVCOMPDEFS = ... -DWRF_HYDRO

# Check executables
ls -la $WRF_ROOT/bin/wrf.exe $WRF_ROOT/bin/real.exe
```

Expected sizes (approximate):

| File | Size |
|------|------|
| `wrf.exe` | ~47 MB |
| `real.exe` | ~37 MB |
| `ndown.exe` | ~41 MB |
| `tc.exe` | ~37 MB |

Run the bundled verification script:

```bash
bash examples/verify_installation.sh
```

---

## Full installation from scratch

### Step 1 — Clone this repository on Lengau

```bash
cd ~
git clone https://github.com/msovara/wrf-hydro-coupled-lengau.git
cd wrf-hydro-coupled-lengau
```

### Step 2 — Download WRF source (DTN)

Compute nodes cannot reach GitHub. Use the DTN:

```bash
ssh msovara@dtn.chpc.ac.za

export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc
mkdir -p $(dirname $INSTALL_DIR)

# Copy scripts from your clone
cp ~/wrf-hydro-coupled-lengau/download_wrf_source.sh $INSTALL_DIR/
cp ~/wrf-hydro-coupled-lengau/checkout_wrf_externals_dtn.sh $INSTALL_DIR/

chmod +x $INSTALL_DIR/*.sh
cd $INSTALL_DIR
./download_wrf_source.sh
```

This creates `$INSTALL_DIR/build/WRF` at tag `v4.7.1`.

### Step 3 — Checkout MMM physics externals (DTN)

Still on the DTN:

```bash
export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc
cd $INSTALL_DIR
./checkout_wrf_externals_dtn.sh
```

Verify:

```bash
ls build/WRF/phys/physics_mmm/.git
find build/WRF/phys/physics_mmm -name '*.F' | head
```

### Step 4 — Build on a compute node

Submit the PBS job (recommended):

```bash
# On login node
cd ~/wrf-hydro-coupled-lengau
qsub examples/run_coupled_hydro_gcc.pbs
```

Or interactive build:

```bash
qsub -I -P RCHPC -q internal \
  -l select=1:ncpus=24:mpiprocs=24:nodetype=haswell_reg \
  -l walltime=10:00:00 -W group_list=chpc_staff

export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc
export TOOLCHAIN=gcc
export WRF_HYDRO=1
export WRF_CONFIG_OPTION=34
export WRF_RUN_CLEAN=0
export MODULE_NAME=wrf-lengau-gcc-hydro

cd $INSTALL_DIR
bash ~/wrf-hydro-coupled-lengau/install_wrf_lengau_clean.sh
```

### Step 5 — Load the module

After a successful build:

```bash
module load chpc/earth/wrf-lengau-gcc-hydro
export WRF_ROOT=/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc
```

---

## Running coupled simulations

### 1. Prepare a case directory

```bash
mkdir -p ~/cases/my_hydro_run
cd ~/cases/my_hydro_run

# WRF static tables
cp $WRF_ROOT/share/wrf/configure.wrf .   # optional reference
# Link or copy standard WRF table files from the WRF source run directory:
ln -sf $WRF_ROOT/build/WRF/run/*.TBL .
ln -sf $WRF_ROOT/build/WRF/run/URBPARM*.TBL .
ln -sf $WRF_ROOT/build/WRF/run/GENPARM.TBL .
ln -sf $WRF_ROOT/build/WRF/run/LANDUSE.TBL .
ln -sf $WRF_ROOT/build/WRF/run/SOILPARM.TBL .
ln -sf $WRF_ROOT/build/WRF/run/VEGPARM.TBL .

# WRF-Hydro template files
cp $WRF_ROOT/share/wrf-hydro/* .
```

### 2. Configure namelists

Coupled runs require **both** WRF and hydro namelist sections:

- **`namelist.input`** — standard WRF domains, physics, time control
- **`hydro.namelist`** — routing, channel parameters, output options
- **`namelist.hrldas`** — land surface (Noah/NoahMP) settings for coupled mode

Key `namelist.input` settings for hydro:

```fortran
&domains
 ! geogrid resolution, e_we, e_sn, etc.
/

&physics
 sf_surface_physics = 2,    ! Noah LSM (or 5 for NoahMP — match hydro config)
/

&hydro
 ! Must be present for coupled mode
 hydro_dt = 300,
 routing_overland = 1,
 routing_channel = 1,
/
```

Consult the [WRF-Hydro documentation](https://wrf-hydro.readthedocs.io/) for routing and forcing options specific to your domain.

### 3. Preprocessing workflow

Standard WRF preprocessing applies:

1. **WPS**: `geogrid` → `ungrib` → `metgrid`
2. **real.exe**: horizontal interpolation and initial conditions
3. **wrf.exe**: coupled integration (atmosphere + land + routing)

```bash
module load chpc/earth/wrf-lengau-gcc-hydro
mpirun -np 24 real.exe
mpirun -np 24 wrf.exe
```

Use a PBS script for production runs (see `examples/run_wrf_coupled.pbs`).

### 4. Output

Coupled runs produce standard WRF output (`wrfout_*`) plus hydro-specific files depending on `hydro.namelist` (e.g. streamflow, groundwater, routing grids). Check your hydro output interval and `io_config_flags` settings.

---

## PBS job workflow

### Build job

Use `examples/run_coupled_hydro_gcc.pbs`:

```bash
qsub examples/run_coupled_hydro_gcc.pbs
qstat -u $USER
tail -f wrf_hydro_gcc.o<JOBID>
```

### Simulation job (template)

See `examples/run_wrf_coupled.pbs`. Typical settings for Lengau Haswell nodes:

```bash
#PBS -P YOUR_PROJECT
#PBS -q normal
#PBS -l select=2:ncpus=24:mpiprocs=24:nodetype=haswell_reg
#PBS -l walltime=24:00:00
```

Adjust `-P`, queue, and node count for your allocation.

---

## Verification checklist

After install, confirm each item:

```bash
# 1. Module loads
module load chpc/earth/wrf-lengau-gcc-hydro

# 2. Executables exist
test -x $WRF_ROOT/bin/wrf.exe && echo OK wrf.exe
test -x $WRF_ROOT/bin/real.exe && echo OK real.exe

# 3. Hydro compile flag
grep -q WRF_HYDRO $WRF_ROOT/share/wrf/configure.wrf && echo OK hydro flag

# 4. MMM physics was present at build time
test -d $WRF_ROOT/build/WRF/phys/physics_mmm/.git && echo OK physics_mmm

# 5. Hydro template files installed
ls $WRF_ROOT/share/wrf-hydro/
```

Or run:

```bash
bash examples/verify_installation.sh
```

---

## Troubleshooting

### Build fails — `phys/physics_mmm` missing

**Symptom:** compile errors, missing physics symbols, empty `phys/physics_mmm`.

**Fix:**

```bash
# On DTN
export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc
./checkout_wrf_externals_dtn.sh

# Rebuild with clean skipped
export WRF_RUN_CLEAN=0
bash install_wrf_lengau_clean.sh
```

### Build fails — linker errors (`init_modules_em_`, etc.)

**Symptom:** `undefined reference` to `dyn_em` symbols after compile.

**Fix:** Usually caused by missing `physics_mmm` or a corrupted tree after `./clean -a`. Re-stage source from DTN checkout; do **not** use `./clean -a` unless you re-run externals checkout immediately after.

Run diagnostics:

```bash
bash diagnose_wrf_compile.sh $WRF_ROOT/build/WRF
```

### PBS script `bad interpreter` after copying from Windows

**Symptom:** `/bin/bash^M: bad interpreter`

**Fix:** Convert line endings on Lengau:

```bash
python3 fix_crlf_clean.py .
```

Never use `tr -d '\r'` — it removes all letter `r` from files.

### `module load` fails

The module file is written to `/apps/chpc/scripts/modules/earth/` during install. If you lack write permission, set `MODULE_DIR` to a personal path and add to `MODULEPATH`:

```bash
export MODULE_DIR=$HOME/modulefiles/earth
mkdir -p $MODULE_DIR
module use $HOME/modulefiles
```

### Intel coupled build fails

As of May 2026, **Intel oneAPI coupled builds fail** on Lengau with `dyn_em` linker errors after 8 compile passes. **Use the GCC coupled build documented here.** Intel standalone WRF-Hydro (`wrf_hydro.exe`) works with oneAPI 2021.3.

---

## Known limitations

| Topic | Status |
|-------|--------|
| Coupled GCC build | **Working** |
| Coupled Intel build | **Not working** on Lengau (linker errors) |
| Standalone `wrf_hydro.exe` | Working (Intel oneAPI, separate install) |
| WPS | Not bundled — install separately if needed |
| Old `setWRF-HYDRO` env | Obsolete — do not use |

---

## Standalone vs coupled

| Mode | Executable | Use case | Install script |
|------|------------|----------|----------------|
| **Coupled** | `wrf.exe` (hydro inside) | Atmosphere + routing in one integration | `install_wrf_lengau_clean.sh` with `WRF_HYDRO=1` |
| **Standalone** | `wrf_hydro.exe` | Offline land/hydrology, no WRF atmosphere | `install_wrf_hydro_standalone_lengau.sh` |

This repository focuses on the **coupled GCC** path because that is the verified production build for WRF + routing on Lengau.

---

## References

- [WRF-Hydro documentation](https://wrf-hydro.readthedocs.io/)
- [WRF-Hydro GitHub](https://github.com/NCAR/wrf_hydro_nwm_public)
- [WRF model](https://www2.mmm.ucar.edu/wrf/users/)
- [WRF GitHub v4.7.1](https://github.com/wrf-model/WRF)
- [CHPC Lengau](https://www.chpc.ac.za/)

---

## Support

Open an issue at [github.com/msovara/wrf-hydro-coupled-lengau/issues](https://github.com/msovara/wrf-hydro-coupled-lengau/issues) with:

- PBS job ID and `build_*.log` tail
- Output of `bash diagnose_wrf_compile.sh $WRF_ROOT/build/WRF`
- `module list` and `echo $WRF_ROOT`
